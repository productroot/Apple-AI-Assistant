//
//  TasksViewModel.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import Foundation
import SwiftUI
import Observation
import FoundationModels
import EventKit

@Observable
final class TasksViewModel {
    // MARK: - Properties
    var tasks: [TodoTask] = []
    var projects: [Project] = []
    var areas: [Area] = []
    
    var selectedFilter: TaskFilter = .section(.today)
    var searchText: String = ""
    var selectedTasks: Set<UUID> = []
    var isMultiSelectMode: Bool = false
    
    private let cloudService = iCloudService.shared
    private var isLoadingFromiCloud = false
    private var isUpdatingFromSync = false
    
    // MARK: - Computed Properties
    var filteredTasks: [TodoTask] {
        var filtered = tasks
        
        switch selectedFilter {
        case .all:
            break
        case .section(let section):
            filtered = tasksForSection(section)
        case .area(let area):
            filtered = tasks.filter { $0.areaId == area.id }
        case .project(let project):
            filtered = tasks.filter { $0.projectId == project.id }
        case .tag(let tag):
            filtered = tasks.filter { $0.tags.contains(tag) }
        case .search(let query):
            filtered = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(query) ||
                task.notes.localizedCaseInsensitiveContains(query)
            }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                task.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered.sorted { lhs, rhs in
            if lhs.priority != rhs.priority {
                return lhs.priority.sortOrder > rhs.priority.sortOrder
            }
            return lhs.createdAt > rhs.createdAt
        }
    }
    
    var todayTasks: [TodoTask] {
        tasksForSection(.today)
    }
    
    var upcomingTasks: [TodoTask] {
        tasksForSection(.upcoming)
    }
    
    var allTags: Set<String> {
        Set(tasks.flatMap { $0.tags })
    }

    var todayTasksByProject: [Project: [TodoTask]] {
        let todayTasks = tasksForSection(.today)
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })
        var groupedTasks: [Project: [TodoTask]] = [:]

        for task in todayTasks {
            guard let projectId = task.projectId, let project = projectMap[projectId] else {
                continue  // Skip tasks without projects
            }
            groupedTasks[project, default: []].append(task)
        }

        return groupedTasks
    }

    var anytimeTasksByProject: [Project: [TodoTask]] {
        let anytimeTasks = tasksForSection(.anytime).filter { !$0.isCompleted }
        let projectMap = Dictionary(uniqueKeysWithValues: projects.map { ($0.id, $0) })

        var groupedTasks: [Project: [TodoTask]] = [:]

        for task in anytimeTasks {
            guard let projectId = task.projectId, let project = projectMap[projectId] else {
                continue
            }
            groupedTasks[project, default: []].append(task)
        }

        return groupedTasks
    }
    
    // MARK: - Initialization
    init() {
        // Always load local data first
        loadLocalData()
        // Don't auto-sync on startup to avoid loops
    }
    
    // MARK: - Task Management
    func addTask(_ task: TodoTask) {
        var taskToAdd = task
        
        // Create reminder if task has reminder time
        if task.reminderTime != nil && task.scheduledDate != nil {
            Task {
                do {
                    if let reminderId = try await TaskReminderService.shared.createReminder(for: task) {
                        taskToAdd.reminderId = reminderId
                        print("📱 Created reminder for task: \(task.title)")
                    }
                } catch {
                    print("❌ Failed to create reminder: \(error)")
                }
            }
        }
        
        tasks.append(taskToAdd)
        saveToiCloudIfEnabled()
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            let oldTask = tasks[index]
            var updatedTask = task
            
            // Handle reminder changes
            Task {
                // Case 1: Reminder was removed
                if oldTask.reminderTime != nil && task.reminderTime == nil {
                    if let reminderId = oldTask.reminderId {
                        do {
                            try await TaskReminderService.shared.deleteReminder(reminderId: reminderId)
                            updatedTask.reminderId = nil
                            print("🗑️ Deleted reminder for task: \(task.title)")
                        } catch {
                            print("❌ Failed to delete reminder: \(error)")
                        }
                    }
                }
                // Case 2: Reminder was added or changed
                else if task.reminderTime != nil && task.scheduledDate != nil {
                    if let existingReminderId = oldTask.reminderId {
                        // Update existing reminder
                        do {
                            try await TaskReminderService.shared.updateReminder(reminderId: existingReminderId, for: task)
                            print("📱 Updated reminder for task: \(task.title)")
                        } catch {
                            print("❌ Failed to update reminder: \(error)")
                        }
                    } else {
                        // Create new reminder
                        do {
                            if let reminderId = try await TaskReminderService.shared.createReminder(for: task) {
                                updatedTask.reminderId = reminderId
                                print("📱 Created reminder for task: \(task.title)")
                                
                                // Update the task in the array with the new reminder ID
                                await MainActor.run {
                                    if let idx = self.tasks.firstIndex(where: { $0.id == task.id }) {
                                        self.tasks[idx].reminderId = reminderId
                                    }
                                }
                            }
                        } catch {
                            print("❌ Failed to create reminder: \(error)")
                        }
                    }
                }
            }
            
            tasks[index] = updatedTask
            
            // Track duration changes
            if oldTask.estimatedDuration != task.estimatedDuration,
               let newDuration = task.estimatedDuration {
                // User manually changed the duration
                DurationLearningService.shared.recordUserOverride(
                    taskId: task.id,
                    userMinutes: Int(newDuration / 60)
                )
                print("👤 User override duration for '\(task.title)': \(Int(newDuration / 60)) minutes")
            }
            
            saveToiCloudIfEnabled()
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        // Delete associated reminder if exists
        if let reminderId = task.reminderId {
            Task {
                do {
                    try await TaskReminderService.shared.deleteReminder(reminderId: reminderId)
                    print("🗑️ Deleted reminder for task: \(task.title)")
                } catch {
                    print("❌ Failed to delete reminder: \(error)")
                }
            }
        }
        
        tasks.removeAll { $0.id == task.id }
        selectedTasks.remove(task.id)
        saveToiCloudIfEnabled()
    }
    
    func startTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].startedAt = Date()
            print("▶️ Started task '\(task.title)' at \(Date())")
            saveToiCloudIfEnabled()
        }
    }
    
    func deleteTasks(_ taskIds: Set<UUID>) {
        tasks.removeAll { taskIds.contains($0.id) }
        selectedTasks.removeAll()
        saveToiCloudIfEnabled()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        
        if updatedTask.isCompleted {
            // Task is being completed
            updatedTask.completionDate = Date()
            
            // Complete associated reminder if exists
            if let reminderId = updatedTask.reminderId {
                Task {
                    do {
                        try await TaskReminderService.shared.completeReminder(reminderId: reminderId)
                        print("✅ Completed reminder for task: \(updatedTask.title)")
                    } catch {
                        print("❌ Failed to complete reminder: \(error)")
                    }
                }
            }
            
            // Calculate actual duration if task was started
            if let startedAt = updatedTask.startedAt {
                let actualDuration = Date().timeIntervalSince(startedAt)
                let actualMinutes = Int(actualDuration / 60)
                
                // Record the actual duration for learning
                DurationLearningService.shared.recordCompletion(
                    taskId: task.id,
                    actualMinutes: actualMinutes
                )
                
                print("⏱️ Task '\(task.title)' completed in \(actualMinutes) minutes")
            }
        } else {
            // Task is being uncompleted
            updatedTask.completionDate = nil
            updatedTask.startedAt = nil
        }
        
        // Handle recurring tasks
        if updatedTask.isCompleted, let recurrenceRule = updatedTask.recurrenceRule {
            print("🔄 Handling recurring task completion: \(updatedTask.title)")
            
            // Create a new task for the next occurrence
            var nextTask = TodoTask(
                title: updatedTask.title,
                notes: updatedTask.notes,
                tags: updatedTask.tags,
                projectId: updatedTask.projectId,
                areaId: updatedTask.areaId,
                priority: updatedTask.priority,
                estimatedDuration: updatedTask.estimatedDuration,
                reminderTime: updatedTask.reminderTime
            )
            
            // Set the recurrence info
            nextTask.recurrenceRule = recurrenceRule
            nextTask.customRecurrence = updatedTask.customRecurrence
            nextTask.parentTaskId = updatedTask.parentTaskId ?? updatedTask.id
            
            // Calculate next occurrence dates
            let baseDate = updatedTask.scheduledDate ?? updatedTask.dueDate ?? Date()
            
            if recurrenceRule == .custom, let customRecurrence = updatedTask.customRecurrence {
                // Handle custom recurrence
                if let nextDate = calculateCustomNextOccurrence(from: baseDate, customRecurrence: customRecurrence) {
                    if updatedTask.scheduledDate != nil {
                        nextTask.scheduledDate = nextDate
                    }
                    if updatedTask.dueDate != nil {
                        nextTask.dueDate = nextDate
                    }
                    addTask(nextTask)
                    print("✅ Created next recurring task with custom rule for date: \(nextDate)")
                }
            } else {
                // Use built-in recurrence rule
                if let nextDate = recurrenceRule.nextOccurrence(from: baseDate) {
                    if updatedTask.scheduledDate != nil {
                        nextTask.scheduledDate = nextDate
                    }
                    if updatedTask.dueDate != nil {
                        nextTask.dueDate = nextDate
                    }
                    addTask(nextTask)
                    print("✅ Created next recurring task for date: \(nextDate)")
                }
            }
        }
        
        updateTask(updatedTask)
    }
    
    private func calculateCustomNextOccurrence(from date: Date, customRecurrence: CustomRecurrence) -> Date? {
        let calendar = Calendar.current
        
        // Check if we've reached the end date
        if let endDate = customRecurrence.endDate {
            let nextDate = calendar.date(byAdding: customRecurrence.unit.calendarComponent, value: customRecurrence.interval, to: date)
            if let next = nextDate, next > endDate {
                return nil
            }
        }
        
        // Calculate next occurrence based on unit and interval
        if customRecurrence.unit == .week, let selectedDays = customRecurrence.selectedDays, !selectedDays.isEmpty {
            // Handle weekly recurrence with specific days
            var candidateDate = date
            _ = calendar.component(.weekday, from: candidateDate) - 1 // 0-based
            
            // Find next valid day
            for _ in 0..<(customRecurrence.interval * 7 + 7) { // Check up to interval weeks + 1
                candidateDate = calendar.date(byAdding: .day, value: 1, to: candidateDate)!
                let weekday = calendar.component(.weekday, from: candidateDate) - 1
                
                if selectedDays.contains(weekday) {
                    // Check if we're in the right week interval
                    let weeksDiff = calendar.dateComponents([.weekOfYear], from: date, to: candidateDate).weekOfYear ?? 0
                    if weeksDiff >= customRecurrence.interval {
                        return candidateDate
                    }
                }
            }
            return nil
        } else if customRecurrence.unit == .month {
            // Handle monthly recurrence
            guard let nextMonth = calendar.date(byAdding: .month, value: customRecurrence.interval, to: date) else {
                return nil
            }
            
            if let monthlyOption = customRecurrence.monthlyOption {
                switch monthlyOption {
                case .sameDay:
                    if let dayOfMonth = customRecurrence.dayOfMonth {
                        var components = calendar.dateComponents([.year, .month], from: nextMonth)
                        components.day = dayOfMonth
                        
                        // If the day doesn't exist in this month (e.g., Feb 31), use the last day
                        if let targetDate = calendar.date(from: components) {
                            return targetDate
                        } else {
                            // Get last day of month
                            components.day = nil
                            if let firstOfMonth = calendar.date(from: components),
                               let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) {
                                return lastOfMonth
                            }
                        }
                    }
                case .lastDay:
                    // Get last day of next month
                    var components = calendar.dateComponents([.year, .month], from: nextMonth)
                    components.day = nil
                    if let firstOfMonth = calendar.date(from: components),
                       let lastOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstOfMonth) {
                        return lastOfMonth
                    }
                }
            }
            
            return nextMonth
        } else {
            // Simple interval-based calculation for other units
            return calendar.date(byAdding: customRecurrence.unit.calendarComponent, value: customRecurrence.interval, to: date)
        }
    }
    
    func moveTasks(_ taskIds: Set<UUID>, to destination: TaskFilter) {
        for id in taskIds {
            if let index = tasks.firstIndex(where: { $0.id == id }) {
                switch destination {
                case .section(let section):
                    tasks[index].scheduledDate = dateForSection(section)
                case .area(let area):
                    tasks[index].areaId = area.id
                case .project(let project):
                    tasks[index].projectId = project.id
                default:
                    break
                }
            }
        }
        selectedTasks.removeAll()
    }
    
    // MARK: - Project Management
    func addProject(_ project: Project) {
        projects.append(project)
        print("DEBUG: Added project '\(project.name)' with id \(project.id), total projects: \(projects.count)")
        saveToiCloudIfEnabled()
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
            saveToiCloudIfEnabled()
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        tasks.removeAll { $0.projectId == project.id }
        saveToiCloudIfEnabled()
    }
    
    // MARK: - Area Management
    func addArea(_ area: Area, at index: Int? = nil) {
        if let index = index, index >= 0 && index <= areas.count {
            areas.insert(area, at: index)
        } else {
            areas.append(area)
        }
        saveToiCloudIfEnabled()
    }
    
    func updateArea(_ area: Area) {
        if let index = areas.firstIndex(where: { $0.id == area.id }) {
            areas[index] = area
            saveToiCloudIfEnabled()
        }
    }
    
    func deleteArea(_ area: Area) {
        areas.removeAll { $0.id == area.id }
        tasks.removeAll { $0.areaId == area.id }
        projects.removeAll { $0.areaId == area.id }
        saveToiCloudIfEnabled()
    }
    
    // MARK: - Private Methods
    private func tasksForSection(_ section: TaskSection) -> [TodoTask] {
        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        
        switch section {
        case .inbox:
            return tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId == nil }
        case .today:
            return tasks.filter { task in
                !task.isCompleted &&
                (task.scheduledDate != nil && task.scheduledDate! < endOfToday)
            }
        case .upcoming:
            return tasks.filter { task in
                !task.isCompleted &&
                task.scheduledDate != nil &&
                task.scheduledDate! >= endOfToday
            }
        case .anytime:
            return tasks.filter { !$0.isCompleted && $0.projectId != nil }
        case .someday:
            return tasks.filter { !$0.isCompleted && $0.tags.contains("someday") }
        case .logbook:
            return tasks.filter { $0.isCompleted }.sorted { ($0.completionDate ?? Date()) > ($1.completionDate ?? Date()) }
        }
    }
    
    private func dateForSection(_ section: TaskSection) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        
        switch section {
        case .today:
            return calendar.startOfDay(for: now)
        case .upcoming:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))
        default:
            return nil
        }
    }
    
    // MARK: - Sample Data
    private func loadSampleData() {
        // Create sample areas
        let workArea = Area(name: "Work", icon: "briefcase", color: "blue")
        let personalArea = Area(name: "Personal", icon: "person", color: "green")
        areas = [workArea, personalArea]
        
        // Create sample projects
        let appProject = Project(
            name: "iOS App Development",
            notes: "Build the new task management features",
            deadline: Date().addingTimeInterval(7 * 24 * 60 * 60),
            areaId: workArea.id,
            color: "blue"
        )
        projects = [appProject]
        
        // Create sample tasks
        tasks = [
            TodoTask(
                title: "Review code changes",
                notes: "Check the latest pull requests",
                scheduledDate: Date(),
                projectId: appProject.id,
                priority: .high
            ),
            TodoTask(
                title: "Design new UI components",
                notes: "Create mockups for the task view",
                scheduledDate: Date(),
                projectId: appProject.id,
                priority: .medium
            ),
            TodoTask(
                title: "Write documentation",
                scheduledDate: Date().addingTimeInterval(24 * 60 * 60),
                projectId: appProject.id,
                priority: .low
            ),
            TodoTask(
                title: "Buy groceries",
                tags: ["shopping"],
                scheduledDate: Date(),
                areaId: personalArea.id,
                priority: .medium
            ),
            TodoTask(
                title: "Learn SwiftUI animations",
                tags: ["learning", "someday"],
                priority: .low
            )
        ]
    }
    
    // MARK: - iCloud Sync Methods
    private func loadFromiCloud() {
        guard !isLoadingFromiCloud else { return }
        isLoadingFromiCloud = true
        
        Task {
            do {
                let (fetchedTasks, fetchedProjects, fetchedAreas) = try await cloudService.fetchTasks()
                await MainActor.run {
                    self.isUpdatingFromSync = true
                    self.tasks = fetchedTasks
                    self.projects = fetchedProjects
                    self.areas = fetchedAreas
                    self.isLoadingFromiCloud = false
                    self.isUpdatingFromSync = false
                    
                    if self.tasks.isEmpty && self.projects.isEmpty && self.areas.isEmpty {
                        self.loadSampleData()
                    }
                    
                    self.saveLocally()
                }
            } catch {
                print("Failed to load from iCloud: \(error)")
                await MainActor.run {
                    self.isLoadingFromiCloud = false
                    self.isUpdatingFromSync = false
                    self.loadLocalData()
                }
            }
        }
    }
    
    private func loadLocalData() {
        let decoder = JSONDecoder()
        
        if let tasksData = UserDefaults.standard.data(forKey: "localTasks"),
           let decodedTasks = try? decoder.decode([TodoTask].self, from: tasksData) {
            tasks = decodedTasks
        }
        
        if let projectsData = UserDefaults.standard.data(forKey: "localProjects"),
           let decodedProjects = try? decoder.decode([Project].self, from: projectsData) {
            projects = decodedProjects
        }
        
        if let areasData = UserDefaults.standard.data(forKey: "localAreas"),
           let decodedAreas = try? decoder.decode([Area].self, from: areasData) {
            areas = decodedAreas
        }
        
        if tasks.isEmpty && projects.isEmpty && areas.isEmpty {
            loadSampleData()
        }
    }
    
    private func saveLocally() {
        let encoder = JSONEncoder()
        
        if let tasksData = try? encoder.encode(tasks) {
            UserDefaults.standard.set(tasksData, forKey: "localTasks")
        }
        
        do {
            let projectsData = try encoder.encode(projects)
            UserDefaults.standard.set(projectsData, forKey: "localProjects")
            print("DEBUG: Saved \(projects.count) projects locally")
        } catch {
            print("ERROR: Failed to encode projects: \(error)")
        }
        
        if let areasData = try? encoder.encode(areas) {
            UserDefaults.standard.set(areasData, forKey: "localAreas")
        }
        
        UserDefaults.standard.synchronize()
    }
    
    func saveToiCloudIfEnabled() {
        guard !isUpdatingFromSync else { return }
        
        saveLocally()
        
        guard cloudService.iCloudEnabled else { return }
        
        cloudService.debouncedSaveTasks(tasks, projects: projects, areas: areas)
    }
    
    func syncWithiCloud() {
        guard cloudService.iCloudEnabled else { return }
        loadFromiCloud()
    }
    
    func exportToiCloud() async throws {
        try await cloudService.saveTasks(tasks, projects: projects, areas: areas)
    }
    
    func importFromiCloud() async throws {
        guard !isLoadingFromiCloud else {
            throw iCloudError.syncInProgress
        }
        
        isLoadingFromiCloud = true
        defer { isLoadingFromiCloud = false }
        
        do {
            let (fetchedTasks, fetchedProjects, fetchedAreas) = try await cloudService.fetchTasks()
            
            await MainActor.run {
                self.isUpdatingFromSync = true
                
                // Clear existing data
                self.tasks.removeAll()
                self.projects.removeAll()
                self.areas.removeAll()
                
                // Import new data
                self.areas = fetchedAreas
                self.projects = fetchedProjects
                self.tasks = fetchedTasks
                
                self.isUpdatingFromSync = false
                
                // Save to local storage
                self.saveLocally()
                
                print("Import completed: \(tasks.count) tasks, \(projects.count) projects, \(areas.count) areas")
            }
        } catch {
            await MainActor.run {
                self.isUpdatingFromSync = false
            }
            throw error
        }
    }
    
    func clearAllData() {
        tasks.removeAll()
        projects.removeAll()
        areas.removeAll()
        selectedTasks.removeAll()
        saveLocally()
        
        if cloudService.iCloudEnabled {
            Task {
                try? await cloudService.deleteAllData()
            }
        }
    }
    
    // MARK: - AI Task Optimization
    
    @MainActor
    func optimizeTasks() async throws -> TaskOptimizationAnalysis {
        print("🤖 Starting AI task optimization")
        
        // Prepare task data
        let taskData = tasks.map { task in
            (
                id: task.id.uuidString,
                title: task.title,
                notes: task.notes,
                priority: task.priority.rawValue,
                scheduledDate: task.scheduledDate,
                dueDate: task.dueDate,
                estimatedDuration: task.estimatedDuration != nil ? Int(task.estimatedDuration! / 60) : nil,
                projectId: task.projectId?.uuidString,
                areaId: task.areaId?.uuidString,
                tags: task.tags,
                isCompleted: task.isCompleted,
                recurrenceRule: task.recurrenceRule?.rawValue
            )
        }
        
        // Prepare project data
        let projectData = projects.map { project in
            (
                id: project.id.uuidString,
                name: project.name,
                areaId: project.areaId?.uuidString,
                deadline: project.deadline
            )
        }
        
        // Prepare area data
        let areaData = areas.map { area in
            (
                id: area.id.uuidString,
                name: area.name
            )
        }
        
        // Get user preferences from feedback service
        let userPreferences = OptimizationFeedbackService.shared.getUserPreferences()
        
        // Generate optimization prompt
        let prompt = AIPrompts.taskOptimization(
            tasks: taskData,
            projects: projectData,
            areas: areaData,
            currentDate: Date(),
            userPreferences: userPreferences.isEmpty ? nil : userPreferences
        )
        
        // Use the language model to analyze and optimize
        let session = LanguageModelSession()
        
        let response = try await session.respond(
            to: Prompt(prompt),
            generating: TaskOptimizationAnalysis.self
        )
        
        print("✅ AI optimization completed")
        return response.content
    }
    
    // MARK: - AI Generation
    
    @MainActor
    func estimateTaskDuration(for task: TodoTask) async throws -> TimeInterval {
        print("📊 Estimating duration for task: \(task.title)")
        
        // Get project name if available
        let projectName = task.projectId.flatMap { projectId in
            projects.first { $0.id == projectId }?.name
        }
        
        // Convert checklist items to strings
        let checklistStrings = task.checklistItems.map { $0.title }
        
        // Fetch similar tasks history from DurationLearningService
        let similarTasksHistory = DurationLearningService.shared.findSimilarTasks(
            to: task.title,
            taskNotes: task.notes,
            checklistCount: task.checklistItems.count
        )
        
        // Generate prompt using centralized prompt management
        let prompt = AIPrompts.taskDurationEstimate(
            taskTitle: task.title,
            taskNotes: task.notes.isEmpty ? nil : task.notes,
            checklistItems: checklistStrings,
            projectName: projectName,
            similarTasksHistory: similarTasksHistory
        )
        
        // Use the language model to get duration estimate
        let session = LanguageModelSession()
        
        let response = try await session.respond(
            to: Prompt(prompt),
            generating: TaskDurationEstimate.self
        )
        
        let minutes = response.content.minutes
        print("✅ AI estimated duration: \(minutes) minutes")
        
        return TimeInterval(minutes * 60) // Convert to seconds
    }
    
    func recordDurationEstimation(taskId: UUID, aiEstimate: TimeInterval, taskTitle: String, taskNotes: String, checklistCount: Int) {
        // Get project name if available  
        let task = tasks.first { $0.id == taskId }
        let projectName = task?.projectId.flatMap { projectId in
            projects.first { $0.id == projectId }?.name
        }
        
        // Record in DurationLearningService
        DurationLearningService.shared.recordEstimate(
            taskId: taskId,
            taskTitle: taskTitle,
            taskNotes: taskNotes,
            checklistCount: checklistCount,
            aiEstimateMinutes: Int(aiEstimate / 60),
            projectName: projectName
        )
    }
    
    @MainActor
    func generateProjectDescription(for project: Project) async throws -> String {
        print("🤖 Generating AI description for project: \(project.name)")
        
        // Get area name if available
        let areaName: String? = {
            if let areaId = project.areaId,
               let area = areas.first(where: { $0.id == areaId }) {
                print("   Including area context: \(area.name)")
                return area.name
            }
            return nil
        }()
        
        if !project.notes.isEmpty {
            print("   Including existing notes as context")
        }
        
        if let deadline = project.deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            print("   Including deadline: \(formatter.string(from: deadline))")
        }
        
        // Use centralized prompt
        let prompt = AIPrompts.projectDescription(
            projectName: project.name,
            areaName: areaName,
            existingNotes: project.notes.isEmpty ? nil : project.notes,
            deadline: project.deadline
        )
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: Prompt(prompt),
                generating: ProjectDescription.self
            )
            
            let projectDesc = response.content
            var formattedDescription = projectDesc.description
            
            if !projectDesc.objectives.isEmpty {
                formattedDescription += "\n\nObjectives:\n"
                formattedDescription += projectDesc.objectives.map { "• \($0)" }.joined(separator: "\n")
            }
            
            if !projectDesc.expectedOutcomes.isEmpty {
                formattedDescription += "\n\nExpected Outcomes:\n"
                formattedDescription += projectDesc.expectedOutcomes.map { "• \($0)" }.joined(separator: "\n")
            }
            
            print("✅ AI description generated successfully")
            return formattedDescription
            
        } catch {
            print("❌ Failed to generate AI description: \(error)")
            throw error
        }
    }
    
    @MainActor
    func generateTaskChecklist(for task: TodoTask) async throws -> [ChecklistItem] {
        print("🤖 Generating AI checklist for task: \(task.title)")
        
        // Get project and area context
        var projectName: String?
        var areaName: String?
        
        if let projectId = task.projectId,
           let project = projects.first(where: { $0.id == projectId }) {
            projectName = project.name
            print("   Including project context: \(project.name)")
            
            if let areaId = project.areaId,
               let area = areas.first(where: { $0.id == areaId }) {
                areaName = area.name
                print("   Including area context: \(area.name)")
            }
        }
        
        if !task.notes.isEmpty {
            print("   Including task notes as context")
        }
        
        // Use centralized prompt
        let prompt = AIPrompts.taskChecklist(
            taskTitle: task.title,
            taskNotes: task.notes.isEmpty ? nil : task.notes,
            projectName: projectName,
            areaName: areaName
        )
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: Prompt(prompt),
                generating: TaskChecklist.self
            )
            
            let taskChecklist = response.content
            
            // Convert strings to ChecklistItem objects
            let checklistItems = taskChecklist.items.map { itemTitle in
                ChecklistItem(title: itemTitle)
            }
            
            print("✅ AI checklist generated successfully with \(checklistItems.count) items")
            if let estimatedMinutes = taskChecklist.estimatedTotalMinutes {
                print("   Estimated time: \(estimatedMinutes) minutes")
            }
            if let order = taskChecklist.completionOrder {
                print("   Completion order: \(order)")
            }
            
            return checklistItems
            
        } catch {
            print("❌ Failed to generate AI checklist: \(error)")
            throw error
        }
    }
    
    // MARK: - Workload Analysis
    
    @MainActor
    func generateWorkloadSuggestions(
        workloads: [WorkloadAnalyzer.DailyWorkload],
        insights: WorkloadAnalyzer.WorkloadInsight
    ) async throws -> String {
        print("🤖 Generating workload analysis suggestions")
        
        let prompt = AIPrompts.workloadAnalysis(
            workloads: workloads,
            insights: insights
        )
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: Prompt(prompt))
            
            print("✅ Workload analysis completed")
            return response.content
        } catch {
            print("❌ Failed to generate workload suggestions: \(error)")
            throw error
        }
    }
    
    // MARK: - Recurrence Pattern Analysis
    
    @MainActor
    func analyzeRecurrencePatterns(
        _ patterns: [RecurrencePatternDetector.PatternMatch]
    ) async throws -> String {
        print("🤖 Analyzing recurrence patterns with AI")
        
        // Convert patterns to a format suitable for the prompt
        let completedTasks = patterns.flatMap { pattern in
            pattern.occurrences.map { date in
                (
                    title: pattern.taskTitle,
                    completedAt: date,
                    projectName: nil as String?,
                    tags: [] as [String]
                )
            }
        }
        
        let prompt = AIPrompts.recurrencePatternDetection(
            completedTasks: completedTasks,
            timeFrame: "detected patterns"
        )
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: Prompt(prompt))
            
            print("✅ Recurrence pattern analysis completed")
            return response.content
        } catch {
            print("❌ Failed to analyze recurrence patterns: \(error)")
            throw error
        }
    }
    
    // MARK: - Task Dependency Analysis
    
    @MainActor
    func analyzeDependencies(
        _ graph: TaskDependencyAnalyzer.DependencyGraph
    ) async throws -> String {
        print("🤖 Analyzing task dependencies with AI")
        
        let prompt = AIPrompts.dependencyAnalysis(graph: graph)
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: Prompt(prompt))
            
            print("✅ Dependency analysis completed")
            return response.content
        } catch {
            print("❌ Failed to analyze dependencies: \(error)")
            throw error
        }
    }
    
    // MARK: - Productivity Insights
    
    @MainActor
    func generateProductivityInsights(
        _ dashboard: TaskInsightsAnalyzer.InsightsDashboard
    ) async throws -> String {
        print("🤖 Generating deep productivity insights")
        
        let prompt = AIPrompts.productivityInsights(dashboard: dashboard)
        
        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: Prompt(prompt))
            
            print("✅ Productivity insights generated")
            return response.content
        } catch {
            print("❌ Failed to generate productivity insights: \(error)")
            throw error
        }
    }
}
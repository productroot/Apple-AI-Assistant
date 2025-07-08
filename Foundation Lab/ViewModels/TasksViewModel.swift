//
//  TasksViewModel.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import Foundation
import SwiftUI
import Observation

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
                return lhs.priority.rawValue > rhs.priority.rawValue
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

    var anytimeTasksByProject: [Project: [TodoTask]] {
        let anytimeTasks = tasksForSection(.anytime)
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
        tasks.append(task)
        saveToiCloudIfEnabled()
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
            saveToiCloudIfEnabled()
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        selectedTasks.remove(task.id)
        saveToiCloudIfEnabled()
    }
    
    func deleteTasks(_ taskIds: Set<UUID>) {
        tasks.removeAll { taskIds.contains($0.id) }
        selectedTasks.removeAll()
        saveToiCloudIfEnabled()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completionDate = updatedTask.isCompleted ? Date() : nil
        updateTask(updatedTask)
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
                (task.scheduledDate != nil && task.scheduledDate! >= startOfToday && task.scheduledDate! < endOfToday)
            }
        case .upcoming:
            return tasks.filter { task in
                !task.isCompleted &&
                task.scheduledDate != nil &&
                task.scheduledDate! >= endOfToday
            }
        case .anytime:
            return tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId != nil }
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
}
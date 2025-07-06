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
            return lhs.createdDate > rhs.createdDate
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
    
    // MARK: - Initialization
    init() {
        loadSampleData()
    }
    
    // MARK: - Task Management
    func addTask(_ task: TodoTask) {
        tasks.append(task)
    }
    
    func updateTask(_ task: TodoTask) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }
    
    func deleteTask(_ task: TodoTask) {
        tasks.removeAll { $0.id == task.id }
        selectedTasks.remove(task.id)
    }
    
    func deleteTasks(_ taskIds: Set<UUID>) {
        tasks.removeAll { taskIds.contains($0.id) }
        selectedTasks.removeAll()
    }
    
    func toggleTaskCompletion(_ task: TodoTask) {
        var updatedTask = task
        updatedTask.isCompleted.toggle()
        updatedTask.completedDate = updatedTask.isCompleted ? Date() : nil
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
    }
    
    func updateProject(_ project: Project) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) {
            projects[index] = project
        }
    }
    
    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        tasks.removeAll { $0.projectId == project.id }
    }
    
    // MARK: - Area Management
    func addArea(_ area: Area) {
        areas.append(area)
    }
    
    func updateArea(_ area: Area) {
        if let index = areas.firstIndex(where: { $0.id == area.id }) {
            areas[index] = area
        }
    }
    
    func deleteArea(_ area: Area) {
        areas.removeAll { $0.id == area.id }
        tasks.removeAll { $0.areaId == area.id }
        projects.removeAll { $0.areaId == area.id }
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
            return tasks.filter { $0.isCompleted }.sorted { ($0.completedDate ?? Date()) > ($1.completedDate ?? Date()) }
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
        let workArea = Area(name: "Work", icon: "briefcase", color: .blue)
        let personalArea = Area(name: "Personal", icon: "person", color: .green)
        areas = [workArea, personalArea]
        
        // Create sample projects
        let appProject = Project(
            name: "iOS App Development",
            notes: "Build the new task management features",
            deadline: Date().addingTimeInterval(7 * 24 * 60 * 60),
            areaId: workArea.id,
            color: .blue
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
}
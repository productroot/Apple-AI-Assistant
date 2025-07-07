//
//  TaskModels.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import Foundation
import SwiftUI

// MARK: - TodoTask Model
struct TodoTask: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var notes: String = ""
    var isCompleted: Bool = false
    var tags: Set<String> = []
    var dueDate: Date?
    var scheduledDate: Date?
    var checklist: [ChecklistItem] = []
    var projectId: UUID?
    var areaId: UUID?
    var createdDate: Date = Date()
    var completedDate: Date?
    var priority: Priority = .none
    
    enum Priority: Int, CaseIterable {
        case none = 0
        case low = 1
        case medium = 2
        case high = 3
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .low: return .blue
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var name: String {
            switch self {
            case .none: return "None"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            }
        }
    }
}

// MARK: - Checklist Item
struct ChecklistItem: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
}

// MARK: - Project Model
struct Project: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var notes: String = ""
    var deadline: Date?
    var areaId: UUID?
    var tasks: [TodoTask] = []
    var isCompleted: Bool = false
    var createdDate: Date = Date()
    var completedDate: Date?
    var color: Color = .blue
    
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
}

// MARK: - Area Model
struct Area: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var icon: String = "folder"
    var color: Color = .gray
    var projects: [Project] = []
    var tasks: [TodoTask] = []
}

// MARK: - Task Section
enum TaskSection: String, CaseIterable {
    case inbox = "Inbox"
    case today = "Today"
    case upcoming = "Upcoming"
    case anytime = "Anytime"
    case someday = "Someday"
    case logbook = "Logbook"
    
    var icon: String {
        switch self {
        case .inbox: return "tray"
        case .today: return "star"
        case .upcoming: return "calendar"
        case .anytime: return "square.stack"
        case .someday: return "archivebox"
        case .logbook: return "book.closed"
        }
    }
    
    var color: Color {
        switch self {
        case .inbox: return .blue
        case .today: return .yellow
        case .upcoming: return .purple
        case .anytime: return .green
        case .someday: return .gray
        case .logbook: return .brown
        }
    }
}

// MARK: - Task Filter
enum TaskFilter: Hashable {
    case all
    case section(TaskSection)
    case area(Area)
    case project(Project)
    case tag(String)
    case search(String)
}
//
//  TaskModels.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

// MARK: - TodoTask Model
struct TodoTask: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var isCompleted: Bool = false
    var tags: [String] = []
    var dueDate: Date?
    var scheduledDate: Date?
    var checklistItems: [ChecklistItem] = []
    var projectId: UUID?
    var areaId: UUID?
    var createdAt: Date = Date()
    var completionDate: Date?
    var priority: Priority = .none
    var estimatedDuration: TimeInterval?
    
    enum Priority: String, CaseIterable, Codable {
        case none = "none"
        case low = "low"
        case medium = "medium"
        case high = "high"
        case asap = "asap"
        
        var rawValue: String {
            switch self {
            case .none: return "none"
            case .low: return "low"
            case .medium: return "medium"
            case .high: return "high"
            case .asap: return "asap"
            }
        }
        
        var color: Color {
            switch self {
            case .none: return .gray
            case .low: return .green
            case .medium: return .yellow
            case .high: return .red
            case .asap: return .red
            }
        }
        
        var name: String {
            switch self {
            case .none: return "None"
            case .low: return "Low"
            case .medium: return "Medium"
            case .high: return "High"
            case .asap: return "ASAP"
            }
        }
        
        var icon: String {
            switch self {
            case .none: return "minus"
            case .low: return "arrow.down"
            case .medium: return "arrow.right"
            case .high: return "arrow.up"
            case .asap: return "exclamationmark.triangle.fill"
            }
        }
        
        var sortOrder: Int {
            switch self {
            case .none: return 0
            case .low: return 1
            case .medium: return 2
            case .high: return 3
            case .asap: return 4
            }
        }
    }
}

// MARK: - Checklist Item
struct ChecklistItem: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}

// MARK: - Project Model
struct Project: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var name: String
    var notes: String = ""
    var deadline: Date?
    var areaId: UUID?
    var tasks: [TodoTask] = []
    var isCompleted: Bool = false
    var createdAt: Date = Date()
    var completionDate: Date?
    var color: String = "blue"
    var icon: String = "folder"
    
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedTasks = tasks.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(tasks.count)
    }
}


// MARK: - Area Model
struct Area: Identifiable, Hashable, Codable, Sendable {
    var id = UUID()
    var name: String
    var icon: String = "folder"
    var color: String = "gray"
    var projects: [Project] = []
    var tasks: [TodoTask] = []
    var createdAt: Date = Date()
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

// MARK: - Transferable Conformance
extension Project: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: { $0.id.uuidString })
    }
}

extension Area: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: { $0.id.uuidString })
    }
}



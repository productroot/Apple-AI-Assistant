//
//  TaskModels.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Contacts

// MARK: - Recurrence Rule
enum RecurrenceRule: String, CaseIterable, Codable, Sendable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .daily: return "calendar.day.timeline.left"
        case .weekly: return "calendar.badge.clock"
        case .biweekly: return "calendar.badge.2"
        case .monthly: return "calendar.circle"
        case .yearly: return "calendar.badge.exclamationmark"
        case .weekdays: return "briefcase"
        case .weekends: return "beach.umbrella"
        case .custom: return "gearshape"
        }
    }
    
    func nextOccurrence(from date: Date) -> Date? {
        let calendar = Calendar.current
        switch self {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date)
        case .biweekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: date)
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date)
        case .weekdays:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            while calendar.isDateInWeekend(nextDate) {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate
        case .weekends:
            var nextDate = calendar.date(byAdding: .day, value: 1, to: date)!
            while !calendar.isDateInWeekend(nextDate) {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate)!
            }
            return nextDate
        case .custom:
            return nil
        }
    }
}

// MARK: - Custom Recurrence
struct CustomRecurrence: Codable, Hashable, Sendable {
    enum TimeUnit: String, Codable, CaseIterable {
        case day = "day"
        case week = "week"
        case month = "month"
        case year = "year"
        
        var calendarComponent: Calendar.Component {
            switch self {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }
    
    enum MonthlyOption: String, Codable {
        case sameDay = "sameDay" // e.g., every 15th
        case lastDay = "lastDay" // last day of month
    }
    
    var interval: Int
    var unit: TimeUnit
    var selectedDays: Set<Int>? // For weekly recurrence (0 = Sunday, 6 = Saturday)
    var monthlyOption: MonthlyOption? // For monthly recurrence
    var dayOfMonth: Int? // For monthly recurrence (1-31)
    var endDate: Date?
    var occurrenceCount: Int?
}

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
    var recurrenceRule: RecurrenceRule?
    var customRecurrence: CustomRecurrence?
    var parentTaskId: UUID? // For tracking the original recurring task
    var startedAt: Date? // For tracking actual duration
    var createdFromReminder: Bool = false // For tracking tasks created from chat reminders
    var mentionedContactIds: [String] = [] // Contact identifiers for mentioned contacts
    var titleMentions: [MentionPosition] = [] // Track where mentions appear in title
    var notesMentions: [MentionPosition] = [] // Track where mentions appear in notes
    var reminderTime: Date? // Time for the reminder (combined with scheduledDate)
    var reminderId: String? // EventKit reminder identifier for tracking
    
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

// MARK: - Mention Position
struct MentionPosition: Codable, Hashable, Sendable {
    let contactId: String
    let placeholder: String // The text shown (e.g., "@John")
    let range: NSRange
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
    
    var displayColor: Color {
        Color.projectColor(named: color)
    }
}

// MARK: - Color Extension
extension Color {
    static func projectColor(named colorName: String) -> Color {
        switch colorName {
        case "systemRed": return Color(.systemRed)
        case "systemOrange": return Color(.systemOrange)
        case "systemYellow": return Color(.systemYellow)
        case "systemGreen": return Color(.systemGreen)
        case "systemTeal": return Color(.systemTeal)
        case "systemBlue": return Color(.systemBlue)
        case "systemIndigo": return Color(.systemIndigo)
        case "systemPurple": return Color(.systemPurple)
        case "systemPink": return Color(.systemPink)
        case "systemBrown": return Color(.systemBrown)
        case "systemGray": return Color(.systemGray)
        case "systemGray2": return Color(.systemGray2)
        case "systemGray3": return Color(.systemGray3)
        case "systemGray4": return Color(.systemGray4)
        case "systemGray5": return Color(.systemGray5)
        case "systemGray6": return Color(.systemGray6)
        default: return Color(colorName)
        }
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
    
    var displayColor: Color {
        Color.projectColor(named: color)
    }
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
    
    var description: String {
        switch self {
        case .inbox:
            return "Unscheduled tasks without a project"
        case .today:
            return "Tasks scheduled for today"
        case .upcoming:
            return "Tasks scheduled for the future"
        case .anytime:
            return "Tasks assigned to projects"
        case .someday:
            return "Tasks without dates for future consideration"
        case .logbook:
            return "Completed tasks archive"
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

extension ChecklistItem: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: { item in
            item.id.uuidString
        })
    }
}




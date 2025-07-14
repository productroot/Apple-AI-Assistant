//
//  TaskReminderService.swift
//  Foundation Lab
//
//  Created by Assistant on 7/14/25.
//

import Foundation
import EventKit

class TaskReminderService {
    static let shared = TaskReminderService()
    private let eventStore = EKEventStore()
    
    private init() {}
    
    // MARK: - Permission Check
    
    func checkRemindersAccess() async -> Bool {
        do {
            if #available(macOS 14.0, iOS 17.0, *) {
                return try await eventStore.requestFullAccessToReminders()
            } else {
                return try await eventStore.requestAccess(to: .reminder)
            }
        } catch {
            print("❌ Failed to request reminders access: \(error)")
            return false
        }
    }
    
    // MARK: - Create Reminder
    
    func createReminder(for task: TodoTask) async throws -> String? {
        guard let scheduledDate = task.scheduledDate else {
            print("⚠️ Cannot create reminder: task has no scheduled date")
            return nil
        }
        
        guard let reminderTime = task.reminderTime else {
            print("⚠️ Cannot create reminder: task has no reminder time")
            return nil
        }
        
        // Check access
        let hasAccess = await checkRemindersAccess()
        guard hasAccess else {
            throw TaskReminderError.accessDenied
        }
        
        // Combine scheduled date with reminder time
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        guard let reminderDate = calendar.date(from: combinedComponents) else {
            throw TaskReminderError.invalidDate
        }
        
        // Create reminder
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = task.title
        reminder.notes = task.notes.isEmpty ? nil : task.notes
        reminder.dueDateComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminderDate
        )
        
        // Map task priority to reminder priority
        switch task.priority {
        case .asap:
            reminder.priority = 1
        case .high:
            reminder.priority = 2
        case .medium:
            reminder.priority = 5
        case .low:
            reminder.priority = 9
        case .none:
            reminder.priority = 0
        }
        
        // Set calendar to default reminders list
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        // Save reminder
        try eventStore.save(reminder, commit: true)
        
        print("✅ Created reminder for task: \(task.title)")
        print("   Reminder ID: \(reminder.calendarItemIdentifier)")
        print("   Due: \(reminderDate.formatted())")
        
        return reminder.calendarItemIdentifier
    }
    
    // MARK: - Update Reminder
    
    func updateReminder(reminderId: String, for task: TodoTask) async throws {
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            print("⚠️ Reminder not found, creating new one")
            // If reminder doesn't exist, create a new one
            if let newReminderId = try await createReminder(for: task) {
                // Return the new reminder ID through the task update
                var updatedTask = task
                updatedTask.reminderId = newReminderId
                // Note: The caller should update the task in the view model
            }
            return
        }
        
        // Update reminder properties
        reminder.title = task.title
        reminder.notes = task.notes.isEmpty ? nil : task.notes
        
        // Update reminder time if changed
        if let scheduledDate = task.scheduledDate, let reminderTime = task.reminderTime {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: reminderTime)
            
            var combinedComponents = DateComponents()
            combinedComponents.year = dateComponents.year
            combinedComponents.month = dateComponents.month
            combinedComponents.day = dateComponents.day
            combinedComponents.hour = timeComponents.hour
            combinedComponents.minute = timeComponents.minute
            
            reminder.dueDateComponents = combinedComponents
        }
        
        // Update priority
        switch task.priority {
        case .asap:
            reminder.priority = 1
        case .high:
            reminder.priority = 2
        case .medium:
            reminder.priority = 5
        case .low:
            reminder.priority = 9
        case .none:
            reminder.priority = 0
        }
        
        // Save changes
        try eventStore.save(reminder, commit: true)
        
        print("✅ Updated reminder for task: \(task.title)")
    }
    
    // MARK: - Delete Reminder
    
    func deleteReminder(reminderId: String) async throws {
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            print("⚠️ Reminder not found for deletion: \(reminderId)")
            return
        }
        
        try eventStore.remove(reminder, commit: true)
        print("✅ Deleted reminder: \(reminder.title ?? "Untitled")")
    }
    
    // MARK: - Complete Reminder
    
    func completeReminder(reminderId: String) async throws {
        guard let reminder = eventStore.calendarItem(withIdentifier: reminderId) as? EKReminder else {
            print("⚠️ Reminder not found for completion: \(reminderId)")
            return
        }
        
        reminder.isCompleted = true
        reminder.completionDate = Date()
        
        try eventStore.save(reminder, commit: true)
        print("✅ Completed reminder: \(reminder.title ?? "Untitled")")
    }
}

// MARK: - Error Types

enum TaskReminderError: LocalizedError {
    case accessDenied
    case invalidDate
    case reminderNotFound
    
    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Access to reminders denied. Please grant permission in Settings."
        case .invalidDate:
            return "Invalid date combination for reminder."
        case .reminderNotFound:
            return "Reminder not found."
        }
    }
}
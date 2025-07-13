//
//  HelpTopicsView.swift
//  Foundation Lab
//
//  Created by Assistant on 7/13/25.
//

import SwiftUI

struct HelpTopicsView: View {
    @State private var searchText = ""
    
    var body: some View {
        List {
            // Getting Started
            Section("Getting Started") {
                HelpTopicRow(
                    icon: "play.circle",
                    title: "Quick Start Guide",
                    description: "Learn the basics of task management"
                )
                
                HelpTopicRow(
                    icon: "rectangle.stack",
                    title: "Understanding Areas & Projects",
                    description: "Organize your tasks hierarchically"
                )
                
                HelpTopicRow(
                    icon: "hand.draw",
                    title: "Gestures & Navigation",
                    description: "Swipe actions, drag & drop, and more"
                )
            }
            
            // Task Management
            Section("Task Management") {
                HelpTopicRow(
                    icon: "plus.circle",
                    title: "Creating Tasks",
                    description: "Add tasks with title, notes, and metadata"
                )
                
                HelpTopicRow(
                    icon: "calendar",
                    title: "Scheduling & Due Dates",
                    description: "Set when tasks should be completed"
                )
                
                HelpTopicRow(
                    icon: "arrow.clockwise",
                    title: "Recurring Tasks",
                    description: "Set up tasks that repeat automatically"
                )
                
                HelpTopicRow(
                    icon: "exclamationmark.triangle",
                    title: "Priority Levels",
                    description: "ASAP, High, Medium, Low, and None"
                )
            }
            
            // Organization
            Section("Organization") {
                HelpTopicRow(
                    icon: "folder",
                    title: "Using Areas",
                    description: "Group related projects together"
                )
                
                HelpTopicRow(
                    icon: "doc.text",
                    title: "Managing Projects",
                    description: "Create projects with deadlines and progress tracking"
                )
                
                HelpTopicRow(
                    icon: "tag",
                    title: "Tags & Labels",
                    description: "Categorize tasks with custom tags"
                )
            }
            
            // Collaboration
            Section("Collaboration") {
                HelpTopicRow(
                    icon: "at",
                    title: "Mentioning Contacts",
                    description: "Link contacts to tasks for better tracking"
                )
                
                HelpTopicRow(
                    icon: "square.and.arrow.up",
                    title: "Sharing Tasks",
                    description: "Export and share task information"
                )
            }
            
            // Advanced Features
            Section("Advanced Features") {
                HelpTopicRow(
                    icon: "icloud",
                    title: "iCloud Sync",
                    description: "Keep tasks synchronized across devices"
                )
                
                HelpTopicRow(
                    icon: "magnifyingglass",
                    title: "Smart Search",
                    description: "Find tasks quickly with advanced filters"
                )
                
                HelpTopicRow(
                    icon: "chart.bar",
                    title: "Task Analytics",
                    description: "View your productivity insights"
                )
            }
            
            // Troubleshooting
            Section("Troubleshooting") {
                HelpTopicRow(
                    icon: "wrench",
                    title: "Common Issues",
                    description: "Solutions to frequent problems"
                )
                
                HelpTopicRow(
                    icon: "icloud.slash",
                    title: "Sync Issues",
                    description: "Troubleshoot iCloud sync problems"
                )
                
                HelpTopicRow(
                    icon: "ant.circle",
                    title: "Report a Bug",
                    description: "Help us improve the app"
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search help topics")
        .navigationTitle("Help Topics")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpTopicRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        NavigationLink(destination: HelpTopicDetailView(topic: title)) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
}

struct HelpTopicDetailView: View {
    let topic: String
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(helpContent[topic]?.overview ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Dynamic content based on topic
                if let content = helpContent[topic] {
                    ForEach(content.sections, id: \.title) { section in
                        HelpSectionView(section: section)
                    }
                } else {
                    Text("Help content coming soon...")
                        .padding()
                        .foregroundColor(.secondary)
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HelpSection {
    let title: String
    let content: [HelpItem]
}

struct HelpItem {
    let type: HelpItemType
    let content: String
}

enum HelpItemType {
    case text
    case step
    case tip
    case warning
    case example
}

struct HelpSectionView: View {
    let section: HelpSection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.headline)
                .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(section.content.enumerated()), id: \.offset) { index, item in
                    HelpItemView(item: item, index: index)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

struct HelpItemView: View {
    let item: HelpItem
    let index: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            switch item.type {
            case .text:
                Text(item.content)
                    .foregroundColor(.secondary)
            case .step:
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                    Text(item.content)
                        .foregroundColor(.secondary)
                }
            case .tip:
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                    Text(item.content)
                        .foregroundColor(.secondary)
                }
            case .warning:
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text(item.content)
                        .foregroundColor(.secondary)
                }
            case .example:
                VStack(alignment: .leading, spacing: 4) {
                    Text("Example:")
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(item.content)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }
        }
    }
}

// Help Content Data
let helpContent: [String: (overview: String, sections: [HelpSection])] = [
    "Quick Start Guide": (
        overview: "Get up and running with task management in just a few minutes",
        sections: [
            HelpSection(
                title: "Creating Your First Task",
                content: [
                    HelpItem(type: .step, content: "Tap the + button in the Tasks view"),
                    HelpItem(type: .step, content: "Enter a title for your task"),
                    HelpItem(type: .step, content: "Optionally add notes, set priority, or schedule a date"),
                    HelpItem(type: .step, content: "Tap Save to create the task"),
                    HelpItem(type: .tip, content: "Use @ to mention contacts in your task")
                ]
            ),
            HelpSection(
                title: "Essential Features",
                content: [
                    HelpItem(type: .text, content: "Swipe right on a task to mark it complete"),
                    HelpItem(type: .text, content: "Swipe left to edit or delete a task"),
                    HelpItem(type: .text, content: "Tap on a task to view or edit details"),
                    HelpItem(type: .text, content: "Use the AI Tools menu for smart features")
                ]
            )
        ]
    ),
    
    "Understanding Areas & Projects": (
        overview: "Organize your tasks with a hierarchical structure",
        sections: [
            HelpSection(
                title: "What are Areas?",
                content: [
                    HelpItem(type: .text, content: "Areas are high-level categories that group related projects together. Think of them as different aspects of your life or work."),
                    HelpItem(type: .example, content: "Personal, Work, Health, Finance, Learning")
                ]
            ),
            HelpSection(
                title: "What are Projects?",
                content: [
                    HelpItem(type: .text, content: "Projects are specific outcomes or goals within an Area. They contain related tasks and have optional deadlines."),
                    HelpItem(type: .example, content: "Website Redesign, Vacation Planning, Home Renovation")
                ]
            ),
            HelpSection(
                title: "Creating Areas and Projects",
                content: [
                    HelpItem(type: .step, content: "Tap 'New Area' to create an area"),
                    HelpItem(type: .step, content: "Choose a name, icon, and color"),
                    HelpItem(type: .step, content: "Tap 'New Project' within an area"),
                    HelpItem(type: .step, content: "Set project details and deadline"),
                    HelpItem(type: .tip, content: "Drag projects between areas to reorganize")
                ]
            )
        ]
    ),
    
    "Gestures & Navigation": (
        overview: "Master the intuitive gestures for efficient task management",
        sections: [
            HelpSection(
                title: "Swipe Actions",
                content: [
                    HelpItem(type: .text, content: "Swipe right → Mark task complete"),
                    HelpItem(type: .text, content: "Swipe left → Edit or delete options"),
                    HelpItem(type: .text, content: "Full swipe right → Quick complete")
                ]
            ),
            HelpSection(
                title: "Drag & Drop",
                content: [
                    HelpItem(type: .text, content: "Long press and drag tasks to reorder"),
                    HelpItem(type: .text, content: "Drag tasks between projects"),
                    HelpItem(type: .text, content: "Drag projects between areas"),
                    HelpItem(type: .warning, content: "Changes are saved automatically")
                ]
            ),
            HelpSection(
                title: "Inline Editing",
                content: [
                    HelpItem(type: .text, content: "Tap on a task to expand and edit inline"),
                    HelpItem(type: .text, content: "Tap outside to save changes"),
                    HelpItem(type: .text, content: "Use keyboard shortcuts for faster editing")
                ]
            )
        ]
    ),
    
    "Creating Tasks": (
        overview: "Learn all the ways to create and customize tasks",
        sections: [
            HelpSection(
                title: "Task Creation Methods",
                content: [
                    HelpItem(type: .text, content: "Tap + button for full task creation"),
                    HelpItem(type: .text, content: "Quick add with floating action button"),
                    HelpItem(type: .text, content: "Create from project or area context"),
                    HelpItem(type: .tip, content: "Tasks created in context auto-assign to that project")
                ]
            ),
            HelpSection(
                title: "Task Properties",
                content: [
                    HelpItem(type: .text, content: "Title: Required, descriptive name"),
                    HelpItem(type: .text, content: "Notes: Additional details or context"),
                    HelpItem(type: .text, content: "Priority: ASAP, High, Medium, Low, None"),
                    HelpItem(type: .text, content: "Schedule: When to work on the task"),
                    HelpItem(type: .text, content: "Duration: Estimated time needed"),
                    HelpItem(type: .text, content: "Checklist: Break down into subtasks"),
                    HelpItem(type: .text, content: "Contacts: @ mention relevant people")
                ]
            )
        ]
    ),
    
    "Scheduling & Due Dates": (
        overview: "Master time management with scheduling features",
        sections: [
            HelpSection(
                title: "Scheduling Options",
                content: [
                    HelpItem(type: .text, content: "Today: Schedule for immediate attention"),
                    HelpItem(type: .text, content: "Tomorrow: Next day planning"),
                    HelpItem(type: .text, content: "This Weekend: For weekend tasks"),
                    HelpItem(type: .text, content: "Next Week: Future planning"),
                    HelpItem(type: .text, content: "Custom: Pick any specific date")
                ]
            ),
            HelpSection(
                title: "Due Dates vs Scheduled Dates",
                content: [
                    HelpItem(type: .text, content: "Scheduled Date: When you plan to work on it"),
                    HelpItem(type: .text, content: "Due Date: Hard deadline for completion"),
                    HelpItem(type: .warning, content: "Overdue tasks appear in red")
                ]
            )
        ]
    ),
    
    "Recurring Tasks": (
        overview: "Set up tasks that repeat automatically",
        sections: [
            HelpSection(
                title: "Recurrence Options",
                content: [
                    HelpItem(type: .text, content: "Daily: Every day"),
                    HelpItem(type: .text, content: "Weekdays: Monday through Friday"),
                    HelpItem(type: .text, content: "Weekends: Saturday and Sunday"),
                    HelpItem(type: .text, content: "Weekly: Same day each week"),
                    HelpItem(type: .text, content: "Biweekly: Every two weeks"),
                    HelpItem(type: .text, content: "Monthly: Same date each month"),
                    HelpItem(type: .text, content: "Yearly: Annual tasks"),
                    HelpItem(type: .text, content: "Custom: Define your own pattern")
                ]
            ),
            HelpSection(
                title: "AI Pattern Detection",
                content: [
                    HelpItem(type: .text, content: "AI analyzes completed tasks for patterns"),
                    HelpItem(type: .text, content: "Suggests recurrence rules automatically"),
                    HelpItem(type: .text, content: "Access via AI Tools → Recurrence Patterns"),
                    HelpItem(type: .tip, content: "Complete tasks consistently for better detection")
                ]
            )
        ]
    ),
    
    "Priority Levels": (
        overview: "Use priorities to focus on what matters most",
        sections: [
            HelpSection(
                title: "Priority System",
                content: [
                    HelpItem(type: .text, content: "ASAP (🔴): Urgent and critical tasks"),
                    HelpItem(type: .text, content: "High (🟠): Important but not urgent"),
                    HelpItem(type: .text, content: "Medium (🟡): Standard priority"),
                    HelpItem(type: .text, content: "Low (🟢): Nice to do when time permits"),
                    HelpItem(type: .text, content: "None (⚪): No specific priority")
                ]
            ),
            HelpSection(
                title: "Best Practices",
                content: [
                    HelpItem(type: .tip, content: "Reserve ASAP for true emergencies"),
                    HelpItem(type: .tip, content: "Most tasks should be Medium priority"),
                    HelpItem(type: .tip, content: "Review and adjust priorities weekly")
                ]
            )
        ]
    ),
    
    "Using Areas": (
        overview: "Organize your life into manageable areas of focus",
        sections: [
            HelpSection(
                title: "Creating Areas",
                content: [
                    HelpItem(type: .step, content: "Tap 'New Area' button"),
                    HelpItem(type: .step, content: "Choose a descriptive name"),
                    HelpItem(type: .step, content: "Select an icon that represents the area"),
                    HelpItem(type: .step, content: "Pick a color for visual distinction"),
                    HelpItem(type: .step, content: "Save to create the area")
                ]
            ),
            HelpSection(
                title: "Area Examples",
                content: [
                    HelpItem(type: .example, content: "Work: Professional projects and tasks"),
                    HelpItem(type: .example, content: "Personal: Life admin and personal goals"),
                    HelpItem(type: .example, content: "Health: Fitness, medical, wellness"),
                    HelpItem(type: .example, content: "Learning: Courses, books, skills"),
                    HelpItem(type: .example, content: "Finance: Budgets, investments, bills")
                ]
            )
        ]
    ),
    
    "Managing Projects": (
        overview: "Track progress on multi-task initiatives",
        sections: [
            HelpSection(
                title: "Project Features",
                content: [
                    HelpItem(type: .text, content: "Set project deadlines"),
                    HelpItem(type: .text, content: "Track completion percentage"),
                    HelpItem(type: .text, content: "Assign to areas for organization"),
                    HelpItem(type: .text, content: "View all tasks within a project"),
                    HelpItem(type: .text, content: "Archive completed projects")
                ]
            ),
            HelpSection(
                title: "Project Management Tips",
                content: [
                    HelpItem(type: .tip, content: "Break large projects into smaller tasks"),
                    HelpItem(type: .tip, content: "Set realistic deadlines with buffer time"),
                    HelpItem(type: .tip, content: "Review project progress weekly"),
                    HelpItem(type: .warning, content: "Orphan projects (no area) appear separately")
                ]
            )
        ]
    ),
    
    "Tags & Labels": (
        overview: "Categorize tasks for easy filtering and search",
        sections: [
            HelpSection(
                title: "Using Tags",
                content: [
                    HelpItem(type: .text, content: "Add tags when creating or editing tasks"),
                    HelpItem(type: .text, content: "Use # symbol to denote tags"),
                    HelpItem(type: .text, content: "Tags appear as colored chips"),
                    HelpItem(type: .text, content: "Filter tasks by tags in search")
                ]
            ),
            HelpSection(
                title: "Tag Strategies",
                content: [
                    HelpItem(type: .example, content: "#urgent #client #bug #feature"),
                    HelpItem(type: .tip, content: "Keep tags short and consistent"),
                    HelpItem(type: .tip, content: "Use tags for contexts like #home #office"),
                    HelpItem(type: .tip, content: "Create a tag taxonomy for your workflow")
                ]
            )
        ]
    ),
    
    "Mentioning Contacts": (
        overview: "Link contacts to tasks for better collaboration",
        sections: [
            HelpSection(
                title: "How to Mention",
                content: [
                    HelpItem(type: .step, content: "Type @ in task title or notes"),
                    HelpItem(type: .step, content: "Type space to trigger contact search"),
                    HelpItem(type: .step, content: "Select contact from dropdown"),
                    HelpItem(type: .step, content: "Contact appears as interactive pill")
                ]
            ),
            HelpSection(
                title: "Benefits",
                content: [
                    HelpItem(type: .text, content: "Quick access to contact details"),
                    HelpItem(type: .text, content: "Track who's involved in tasks"),
                    HelpItem(type: .text, content: "Filter tasks by mentioned contacts"),
                    HelpItem(type: .tip, content: "Grant Contacts permission when prompted")
                ]
            )
        ]
    ),
    
    "Sharing Tasks": (
        overview: "Export and share task information with others",
        sections: [
            HelpSection(
                title: "Sharing Options",
                content: [
                    HelpItem(type: .text, content: "Share individual task details"),
                    HelpItem(type: .text, content: "Export project task lists"),
                    HelpItem(type: .text, content: "Copy task information as text"),
                    HelpItem(type: .text, content: "Send via Messages, Mail, or other apps")
                ]
            ),
            HelpSection(
                title: "Export Formats",
                content: [
                    HelpItem(type: .text, content: "Plain text for easy reading"),
                    HelpItem(type: .text, content: "Markdown for formatted documents"),
                    HelpItem(type: .text, content: "JSON for data transfer")
                ]
            )
        ]
    ),
    
    "iCloud Sync": (
        overview: "Keep your tasks synchronized across all your devices",
        sections: [
            HelpSection(
                title: "Enabling iCloud Sync",
                content: [
                    HelpItem(type: .step, content: "Go to Settings"),
                    HelpItem(type: .step, content: "Toggle 'Enable iCloud Sync'"),
                    HelpItem(type: .step, content: "Tasks will sync automatically"),
                    HelpItem(type: .warning, content: "Requires iCloud Drive to be enabled")
                ]
            ),
            HelpSection(
                title: "Sync Features",
                content: [
                    HelpItem(type: .text, content: "Automatic background sync"),
                    HelpItem(type: .text, content: "Manual sync option available"),
                    HelpItem(type: .text, content: "Conflict resolution for edits"),
                    HelpItem(type: .text, content: "Offline support with sync on reconnect")
                ]
            )
        ]
    ),
    
    "Smart Search": (
        overview: "Find tasks quickly with powerful search features",
        sections: [
            HelpSection(
                title: "Search Capabilities",
                content: [
                    HelpItem(type: .text, content: "Search by task title"),
                    HelpItem(type: .text, content: "Search in notes and descriptions"),
                    HelpItem(type: .text, content: "Filter by project or area"),
                    HelpItem(type: .text, content: "Filter by priority or status"),
                    HelpItem(type: .text, content: "Search by mentioned contacts"),
                    HelpItem(type: .text, content: "Filter by tags")
                ]
            ),
            HelpSection(
                title: "Search Tips",
                content: [
                    HelpItem(type: .tip, content: "Use quotes for exact phrases"),
                    HelpItem(type: .tip, content: "Combine filters for precise results"),
                    HelpItem(type: .tip, content: "Save frequent searches")
                ]
            )
        ]
    ),
    
    "Task Analytics": (
        overview: "Gain insights into your productivity patterns",
        sections: [
            HelpSection(
                title: "Available Analytics",
                content: [
                    HelpItem(type: .text, content: "Completion rates by day/week/month"),
                    HelpItem(type: .text, content: "Average task completion time"),
                    HelpItem(type: .text, content: "Most productive times of day"),
                    HelpItem(type: .text, content: "Project progress tracking"),
                    HelpItem(type: .text, content: "Priority distribution analysis")
                ]
            ),
            HelpSection(
                title: "Using Insights",
                content: [
                    HelpItem(type: .tip, content: "Schedule important tasks during productive hours"),
                    HelpItem(type: .tip, content: "Balance workload based on completion patterns"),
                    HelpItem(type: .tip, content: "Adjust estimates based on actual durations")
                ]
            )
        ]
    ),
    
    "Common Issues": (
        overview: "Solutions to frequently encountered problems",
        sections: [
            HelpSection(
                title: "Task Issues",
                content: [
                    HelpItem(type: .text, content: "Can't complete task? → Check if it's already marked complete"),
                    HelpItem(type: .text, content: "Task disappeared? → Check filters and completed section"),
                    HelpItem(type: .text, content: "Can't edit? → Tap the task or swipe left for edit"),
                    HelpItem(type: .text, content: "Mentions not working? → Grant Contacts permission")
                ]
            ),
            HelpSection(
                title: "Performance Issues",
                content: [
                    HelpItem(type: .text, content: "App running slow? → Close and reopen the app"),
                    HelpItem(type: .text, content: "Storage full? → Archive old completed tasks"),
                    HelpItem(type: .text, content: "Battery drain? → Disable background sync")
                ]
            )
        ]
    ),
    
    "Sync Issues": (
        overview: "Troubleshoot iCloud synchronization problems",
        sections: [
            HelpSection(
                title: "Common Sync Problems",
                content: [
                    HelpItem(type: .text, content: "Not syncing? → Check internet connection"),
                    HelpItem(type: .text, content: "Missing tasks? → Verify iCloud Drive is enabled"),
                    HelpItem(type: .text, content: "Duplicate tasks? → Use manual sync to resolve"),
                    HelpItem(type: .text, content: "Sync stuck? → Sign out and back into iCloud")
                ]
            ),
            HelpSection(
                title: "Sync Best Practices",
                content: [
                    HelpItem(type: .tip, content: "Keep app updated on all devices"),
                    HelpItem(type: .tip, content: "Wait for sync to complete before switching devices"),
                    HelpItem(type: .tip, content: "Use manual sync after major changes"),
                    HelpItem(type: .warning, content: "Don't edit same task on multiple devices simultaneously")
                ]
            )
        ]
    ),
    
    "Report a Bug": (
        overview: "Help us improve by reporting issues",
        sections: [
            HelpSection(
                title: "Before Reporting",
                content: [
                    HelpItem(type: .step, content: "Update to the latest version"),
                    HelpItem(type: .step, content: "Restart the app"),
                    HelpItem(type: .step, content: "Check if issue persists"),
                    HelpItem(type: .step, content: "Note steps to reproduce")
                ]
            ),
            HelpSection(
                title: "What to Include",
                content: [
                    HelpItem(type: .text, content: "App version number"),
                    HelpItem(type: .text, content: "Device model and iOS version"),
                    HelpItem(type: .text, content: "Steps to reproduce the issue"),
                    HelpItem(type: .text, content: "Screenshots if applicable"),
                    HelpItem(type: .text, content: "Expected vs actual behavior")
                ]
            ),
            HelpSection(
                title: "Contact Support",
                content: [
                    HelpItem(type: .text, content: "Email: support@productroot.io"),
                    HelpItem(type: .text, content: "Include 'Foundation Lab Bug' in subject"),
                    HelpItem(type: .tip, content: "We typically respond within 48 hours")
                ]
            )
        ]
    )
]

#Preview {
    NavigationStack {
        HelpTopicsView()
    }
}
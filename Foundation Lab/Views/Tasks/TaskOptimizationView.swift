//
//  TaskOptimizationView.swift
//  FoundationLab
//
//  Created by Assistant on 7/12/25.
//

import SwiftUI

struct TaskOptimizationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var optimization: TaskOptimizationAnalysis?
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedTaskId: UUID?
    @State private var showingEditSheet = false
    @State private var acceptedTasks: Set<UUID> = []
    @State private var rejectedTasks: Set<UUID> = []
    
    let viewModel: TasksViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else if let optimization = optimization {
                    optimizationResultsView(optimization)
                }
            }
            .navigationTitle("AI Task Optimizer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if optimization != nil {
                        Button("Apply") {
                            applyOptimizations()
                        }
                        .disabled(acceptedTasks.isEmpty)
                    }
                }
            }
        }
        .task {
            await loadOptimization()
        }
        .sheet(isPresented: $showingEditSheet) {
            if let taskId = selectedTaskId,
               let task = viewModel.tasks.first(where: { $0.id == taskId }) {
                TaskOptimizationEditView(
                    task: task,
                    optimizedTask: findOptimizedTask(taskId: taskId),
                    onAccept: { priority, action in
                        handleTaskEdit(taskId: taskId, priority: priority, action: action, accepted: true)
                    },
                    onReject: { priority, action in
                        handleTaskEdit(taskId: taskId, priority: priority, action: action, accepted: false)
                    }
                )
            }
        }
    }
    
    // MARK: - Views
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Analyzing your tasks...")
                .font(.headline)
            
            Text("The AI is reviewing your tasks, projects, and priorities to create an optimized plan.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.red)
            
            Text("Optimization Failed")
                .font(.headline)
            
            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                Task {
                    await loadOptimization()
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func optimizationResultsView(_ optimization: TaskOptimizationAnalysis) -> some View {
        List {
            // Insights Section
            if !optimization.insights.isEmpty {
                Section("AI Insights") {
                    ForEach(optimization.insights, id: \.self) { insight in
                        Label(insight, systemImage: "lightbulb")
                            .font(.caption)
                    }
                }
            }
            
            // Quick Wins
            if !optimization.quickWins.isEmpty {
                taskSection(
                    title: "Quick Wins",
                    icon: "bolt.fill",
                    color: .yellow,
                    tasks: optimization.quickWins
                )
            }
            
            // Urgent Tasks
            if !optimization.urgentTasks.isEmpty {
                taskSection(
                    title: "Urgent",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    tasks: optimization.urgentTasks
                )
            }
            
            // Today Tasks
            if !optimization.todayTasks.isEmpty {
                taskSection(
                    title: "Today",
                    icon: "star.fill",
                    color: .orange,
                    tasks: optimization.todayTasks
                )
            }
            
            // This Week Tasks
            if !optimization.thisWeekTasks.isEmpty {
                taskSection(
                    title: "This Week",
                    icon: "calendar",
                    color: .blue,
                    tasks: optimization.thisWeekTasks
                )
            }
            
            // Later Tasks
            if !optimization.laterTasks.isEmpty {
                taskSection(
                    title: "Later",
                    icon: "clock",
                    color: .gray,
                    tasks: optimization.laterTasks
                )
            }
            
            // Blocked Tasks
            if !optimization.blockedTasks.isEmpty {
                taskSection(
                    title: "Blocked",
                    icon: "lock.fill",
                    color: .purple,
                    tasks: optimization.blockedTasks
                )
            }
            
            // Delegatable Tasks
            if !optimization.delegatableTasks.isEmpty {
                taskSection(
                    title: "Can Delegate/Automate",
                    icon: "person.2.fill",
                    color: .indigo,
                    tasks: optimization.delegatableTasks
                )
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func taskSection(title: String, icon: String, color: Color, tasks: [OptimizedTask]) -> some View {
        Section {
            ForEach(tasks, id: \.taskId) { optimizedTask in
                if let taskId = UUID(uuidString: optimizedTask.taskId),
                   let task = viewModel.tasks.first(where: { $0.id == taskId }) {
                    OptimizedTaskRowView(
                        task: task,
                        optimizedTask: optimizedTask,
                        isAccepted: acceptedTasks.contains(taskId),
                        isRejected: rejectedTasks.contains(taskId),
                        onTap: {
                            selectedTaskId = taskId
                            showingEditSheet = true
                        }
                    )
                }
            }
        } header: {
            Label(title, systemImage: icon)
                .foregroundStyle(color)
        }
    }
    
    // MARK: - Helper Methods
    
    private func findOptimizedTask(taskId: UUID) -> OptimizedTask? {
        guard let optimization = optimization else { return nil }
        
        let allTasks = optimization.urgentTasks + optimization.todayTasks +
                      optimization.thisWeekTasks + optimization.laterTasks +
                      optimization.blockedTasks + optimization.delegatableTasks +
                      optimization.quickWins
        
        return allTasks.first { $0.taskId == taskId.uuidString }
    }
    
    // MARK: - Actions
    
    private func loadOptimization() async {
        isLoading = true
        error = nil
        
        do {
            optimization = try await viewModel.optimizeTasks()
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    private func handleTaskEdit(taskId: UUID, priority: String, action: String, accepted: Bool) {
        if accepted {
            acceptedTasks.insert(taskId)
            rejectedTasks.remove(taskId)
        } else {
            rejectedTasks.insert(taskId)
            acceptedTasks.remove(taskId)
        }
        
        // Record feedback
        if let task = viewModel.tasks.first(where: { $0.id == taskId }),
           let optimized = findOptimizedTask(taskId: taskId) {
            if accepted {
                OptimizationFeedbackService.shared.recordAcceptance(
                    taskId: taskId,
                    originalPriority: task.priority.rawValue,
                    suggestedPriority: optimized.recommendedPriority,
                    suggestedAction: optimized.suggestedAction,
                    reasoning: optimized.reasoning
                )
            } else {
                OptimizationFeedbackService.shared.recordRejection(
                    taskId: taskId,
                    originalPriority: task.priority.rawValue,
                    suggestedPriority: optimized.recommendedPriority,
                    userPriority: priority,
                    suggestedAction: optimized.suggestedAction,
                    userAction: action,
                    reasoning: optimized.reasoning
                )
            }
        }
        
        showingEditSheet = false
    }
    
    private func applyOptimizations() {
        // Apply accepted optimizations
        for taskId in acceptedTasks {
            guard let optimized = findOptimizedTask(taskId: taskId),
                  let task = viewModel.tasks.first(where: { $0.id == taskId }) else { continue }
            
            var updatedTask = task
            
            // Update priority based on recommendation
            switch optimized.recommendedPriority {
            case "A1", "A2":
                updatedTask.priority = .high
            case "B1", "B2":
                updatedTask.priority = .medium
            case "C":
                updatedTask.priority = .low
            default:
                break
            }
            
            // Update scheduled date based on action
            switch optimized.suggestedAction {
            case "do_now":
                updatedTask.scheduledDate = Date()
            case "schedule":
                if let timeSlot = optimized.optimalTimeSlot {
                    updatedTask.scheduledDate = nextTimeSlot(for: timeSlot)
                }
            default:
                break
            }
            
            viewModel.updateTask(updatedTask)
        }
        
        dismiss()
    }
    
    private func nextTimeSlot(for slot: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch slot {
        case "morning":
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 9
            components.minute = 0
            if let date = calendar.date(from: components), date > now {
                return date
            } else {
                return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
            }
        case "afternoon":
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 14
            components.minute = 0
            if let date = calendar.date(from: components), date > now {
                return date
            } else {
                return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
            }
        case "evening":
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 18
            components.minute = 0
            if let date = calendar.date(from: components), date > now {
                return date
            } else {
                return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)!
            }
        default:
            return now
        }
    }
}

// MARK: - Optimized Task Row View

struct OptimizedTaskRowView: View {
    let task: TodoTask
    let optimizedTask: OptimizedTask
    let isAccepted: Bool
    let isRejected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Task title and status
                HStack {
                    Text(task.title)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    if isAccepted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else if isRejected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                
                // AI recommendation
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Priority recommendation
                        Label(optimizedTask.recommendedPriority, systemImage: "flag.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        // Action recommendation
                        Label(actionDisplayText(optimizedTask.suggestedAction), systemImage: actionIcon(optimizedTask.suggestedAction))
                            .font(.caption)
                            .foregroundStyle(.purple)
                        
                        // Duration if available
                        if let duration = optimizedTask.estimatedFocusMinutes {
                            Label("\(duration)m", systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    // Reasoning
                    Text(optimizedTask.reasoning)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func actionDisplayText(_ action: String) -> String {
        switch action {
        case "do_now": return "Do Now"
        case "schedule": return "Schedule"
        case "delegate": return "Delegate"
        case "automate": return "Automate"
        case "delete": return "Delete"
        case "batch_with_similar": return "Batch"
        default: return action
        }
    }
    
    private func actionIcon(_ action: String) -> String {
        switch action {
        case "do_now": return "bolt"
        case "schedule": return "calendar"
        case "delegate": return "person.2"
        case "automate": return "gearshape"
        case "delete": return "trash"
        case "batch_with_similar": return "square.stack"
        default: return "questionmark"
        }
    }
}

// MARK: - Task Optimization Edit View

struct TaskOptimizationEditView: View {
    let task: TodoTask
    let optimizedTask: OptimizedTask?
    let onAccept: (String, String) -> Void
    let onReject: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPriority: String
    @State private var selectedAction: String
    
    init(task: TodoTask, optimizedTask: OptimizedTask?, onAccept: @escaping (String, String) -> Void, onReject: @escaping (String, String) -> Void) {
        self.task = task
        self.optimizedTask = optimizedTask
        self.onAccept = onAccept
        self.onReject = onReject
        
        _selectedPriority = State(initialValue: optimizedTask?.recommendedPriority ?? task.priority.rawValue)
        _selectedAction = State(initialValue: optimizedTask?.suggestedAction ?? "do_now")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task") {
                    VStack(alignment: .leading) {
                        Text(task.title)
                            .font(.headline)
                        
                        if !task.notes.isEmpty {
                            Text(task.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                if let optimizedTask = optimizedTask {
                    Section("AI Recommendation") {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(optimizedTask.recommendedPriority, systemImage: "flag.fill")
                                .foregroundStyle(.blue)
                            
                            Label(actionDisplayText(optimizedTask.suggestedAction), systemImage: actionIcon(optimizedTask.suggestedAction))
                                .foregroundStyle(.purple)
                            
                            Text(optimizedTask.reasoning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("Your Choice") {
                    Picker("Priority", selection: $selectedPriority) {
                        Text("A1 - Urgent & Important").tag("A1")
                        Text("A2 - Important").tag("A2")
                        Text("B1 - Urgent").tag("B1")
                        Text("B2 - Routine").tag("B2")
                        Text("C - Nice to Have").tag("C")
                    }
                    
                    Picker("Action", selection: $selectedAction) {
                        Text("Do Now").tag("do_now")
                        Text("Schedule").tag("schedule")
                        Text("Delegate").tag("delegate")
                        Text("Automate").tag("automate")
                        Text("Delete").tag("delete")
                        Text("Batch with Similar").tag("batch_with_similar")
                    }
                }
            }
            .navigationTitle("Review Optimization")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Reject") {
                            onReject(selectedPriority, selectedAction)
                            dismiss()
                        }
                        .foregroundStyle(.red)
                        
                        Button("Accept") {
                            onAccept(selectedPriority, selectedAction)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
    }
    
    private func actionDisplayText(_ action: String) -> String {
        switch action {
        case "do_now": return "Do Now"
        case "schedule": return "Schedule"
        case "delegate": return "Delegate"
        case "automate": return "Automate"
        case "delete": return "Delete"
        case "batch_with_similar": return "Batch"
        default: return action
        }
    }
    
    private func actionIcon(_ action: String) -> String {
        switch action {
        case "do_now": return "bolt"
        case "schedule": return "calendar"
        case "delegate": return "person.2"
        case "automate": return "gearshape"
        case "delete": return "trash"
        case "batch_with_similar": return "square.stack"
        default: return "questionmark"
        }
    }
}
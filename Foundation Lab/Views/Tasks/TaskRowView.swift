//
//  TaskRowView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TaskRowView: View {
    @State var task: TodoTask
    var viewModel: TasksViewModel
    let isSelected: Bool
    let onTap: () -> Void
    let onEditingChanged: ((Bool, TodoTask) -> Void)?
    let onMoveRequested: ((TodoTask) -> Void)?
    let onDeleteRequested: ((TodoTask) -> Void)?
    let onDuplicateRequested: ((TodoTask) -> Void)?
    let shouldSaveFromParent: Bool


    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedNotes: String
    @State private var editedPriority: TodoTask.Priority
    @State private var editedScheduledDate: Date?
    @State private var showingDatePicker = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool

    init(
        task: TodoTask, 
        viewModel: TasksViewModel, 
        isSelected: Bool, 
        onTap: @escaping () -> Void,
        onEditingChanged: ((Bool, TodoTask) -> Void)? = nil,
        onMoveRequested: ((TodoTask) -> Void)? = nil,
        onDeleteRequested: ((TodoTask) -> Void)? = nil,
        onDuplicateRequested: ((TodoTask) -> Void)? = nil,
        shouldSaveFromParent: Bool = false
    ) {
        _task = State(initialValue: task)
        self.viewModel = viewModel
        self.isSelected = isSelected
        self.onTap = onTap
        self.onEditingChanged = onEditingChanged
        self.onMoveRequested = onMoveRequested
        self.onDeleteRequested = onDeleteRequested
        self.onDuplicateRequested = onDuplicateRequested
        self.shouldSaveFromParent = shouldSaveFromParent
        _editedTitle = State(initialValue: task.title)
        _editedNotes = State(initialValue: task.notes)
        _editedPriority = State(initialValue: task.priority)
        _editedScheduledDate = State(initialValue: task.scheduledDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                expandedEditView
            } else {
                displayView
            }
        }
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing && !task.isCompleted && !viewModel.isMultiSelectMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing = true
                    onEditingChanged?(true, task)
                }
                // Don't focus automatically - let user tap to show keyboard
            } else if !isEditing {
                onTap()
            }
            // Don't handle tap in edit mode here - let the background gesture handle it
        }
        .onChange(of: isTitleFocused) { oldValue, newValue in
            // Auto-save when title field loses focus
            if oldValue && !newValue && isEditing && !isNotesFocused {
                saveTask()
            }
        }
        .onChange(of: isNotesFocused) { oldValue, newValue in
            // Auto-save when notes field loses focus
            if oldValue && !newValue && isEditing && !isTitleFocused {
                saveTask()
            }
        }
        .onChange(of: shouldSaveFromParent) { _, newValue in
            // When parent requests save, save and exit edit mode
            if newValue && isEditing {
                isTitleFocused = false
                isNotesFocused = false
                saveTask()
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            CustomDatePickerView(selectedDate: $editedScheduledDate)
        }

    }

    private var displayView: some View {
        HStack(spacing: 12) {
            // Selection indicator
            if viewModel.isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect)
            }
            
            // Completion button
            Button {
                viewModel.toggleTaskCompletion(task)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect)
            }
            .buttonStyle(.plain)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                
                HStack(spacing: 8) {
                    if task.priority != .none {
                        Image(systemName: task.priority.icon)
                            .font(.caption2)
                            .foregroundStyle(task.priority.color)
                    }
                    
                    if let project = getProjectForTask(task) {
                        Label {
                            Text(project.name)
                        } icon: {
                            Circle()
                                .fill(project.displayColor)
                                .frame(width: 6, height: 6)
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if let scheduledDate = task.scheduledDate {
                        Label {
                            Text(scheduledDate, style: .date)
                        } icon: {
                            Image(systemName: "calendar")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    if !task.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(Array(task.tags), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
            
            Spacer()
            
            // Chevron for detail
            if !viewModel.isMultiSelectMode {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private var expandedEditView: some View {
                 VStack(spacing: 0) {
             // Main editing area
             VStack(spacing: 16) {
                                 // Title Field
                 TextField("Task Title", text: $editedTitle)
                     .font(.body)
                     .textFieldStyle(.plain)
                     .focused($isTitleFocused)
                     .submitLabel(.done)
                     .onSubmit {
                         isTitleFocused = false
                         isNotesFocused = false
                         saveTask()
                     }
                     .toolbar {
                         ToolbarItemGroup(placement: .keyboard) {
                             Spacer()
                             Button("Done") {
                                 isTitleFocused = false
                                 isNotesFocused = false
                                 saveTask()
                             }
                         }
                     }
                
                                 // Notes Field
                 TextField("Notes", text: $editedNotes, axis: .vertical)
                     .font(.body)
                     .textFieldStyle(.plain)
                     .lineLimit(2...4)
                     .focused($isNotesFocused)
                     .onSubmit {
                         isTitleFocused = false
                         isNotesFocused = false
                         saveTask()
                     }
                
                // Metadata Row
                HStack(spacing: 16) {
                    // Priority Picker
                    Menu {
                        ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                            Button {
                                editedPriority = priority
                            } label: {
                                Label(priority.name, systemImage: priority.icon)
                                    .foregroundStyle(priority.color)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: editedPriority.icon)
                                .foregroundStyle(editedPriority.color)
                            Text(editedPriority.name)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                    
                    // Date Picker
                    Menu {
                        Button("Today") { editedScheduledDate = Date() }
                        Button("Tomorrow") { editedScheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) }
                        Button("Next Week") { editedScheduledDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) }
                        Divider()
                        Button("Custom...") { showingDatePicker = true }
                        Divider()
                        Button("No Date", role: .destructive) { editedScheduledDate = nil }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text(editedScheduledDate?.formatted(date: .abbreviated, time: .omitted) ?? "No Date")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                                         
                     Spacer()
                 }
             }
             .padding(.horizontal)
             .padding(.vertical, 12)
             .background(Color(.systemGray6))
        }
        .background(Color(.systemGray6))
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isTitleFocused && !isNotesFocused {
                saveTask()
            }
        }
    }
    
    private func saveTask() {
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        var updatedTask = task
        updatedTask.title = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.notes = editedNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedTask.priority = editedPriority
        updatedTask.scheduledDate = editedScheduledDate
        
        viewModel.updateTask(updatedTask)
        task = updatedTask
        
        // Dismiss keyboard
        isTitleFocused = false
        isNotesFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
            onEditingChanged?(false, task)
        }
    }
    
    private func duplicateTask() {
        onDuplicateRequested?(task)
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
            onEditingChanged?(false, task)
        }
    }
    
    private func getProjectForTask(_ task: TodoTask) -> Project? {
        guard let projectId = task.projectId else { return nil }
        return viewModel.projects.first { $0.id == projectId }
    }
}

// MARK: - Custom Date Picker View
struct CustomDatePickerView: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var tempDate = Date()
    
    init(selectedDate: Binding<Date?>) {
        self._selectedDate = selectedDate
        self._tempDate = State(initialValue: selectedDate.wrappedValue ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick options
                List {
                    Button {
                        selectedDate = Date()
                        dismiss()
                    } label: {
                        Label("Today", systemImage: "star")
                            .foregroundStyle(.yellow)
                    }
                    
                    Button {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        dismiss()
                    } label: {
                        Label("Tomorrow", systemImage: "sun.max")
                            .foregroundStyle(.orange)
                    }
                    
                    Button {
                        selectedDate = nextWeekend()
                        dismiss()
                    } label: {
                        Label("This Weekend", systemImage: "beach.umbrella")
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
                        dismiss()
                    } label: {
                        Label("Next Week", systemImage: "calendar")
                            .foregroundStyle(.green)
                    }
                }
                .listStyle(.insetGrouped)
                .frame(maxHeight: 200)
                
                // Graphical date picker
                DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("When")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDate = tempDate
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        let daysUntilSaturday = (7 - weekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today) ?? today
    }
}
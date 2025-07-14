//
//  TaskRowView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI
import Contacts

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
    @State private var isGeneratingChecklist = false
    @State private var showGenerationError = false
    @State private var generationError: String?
    @State private var newChecklistItem = ""
    @State private var editedRecurrenceRule: RecurrenceRule?
    @State private var editedCustomRecurrence: CustomRecurrence?
    @State private var showingCustomRecurrence = false
    @State private var editedDuration: TimeInterval?
    @State private var isGeneratingDuration = false
    @State private var showDurationPicker = false
    @State private var showingDeleteAlert = false
    @State private var loadedContacts: [CNContact] = []
    @State private var editingMentionedContacts: [CNContact] = []
    @State private var editedReminderTime: Date?
    @State private var hasReminder: Bool = false
    @FocusState private var isTitleFocused: Bool
    @FocusState private var isNotesFocused: Bool
    @FocusState private var isNewChecklistItemFocused: Bool

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
        _editedRecurrenceRule = State(initialValue: task.recurrenceRule)
        _editedCustomRecurrence = State(initialValue: task.customRecurrence)
        _editedDuration = State(initialValue: task.estimatedDuration)
        _editedReminderTime = State(initialValue: task.reminderTime)
        _hasReminder = State(initialValue: task.reminderTime != nil)
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
        .onAppear {
            loadMentionedContacts()
        }
        .onTapGesture {
            if !isEditing && !task.isCompleted && !viewModel.isMultiSelectMode {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isEditing = true
                    onEditingChanged?(true, task)
                    // Load mentioned contacts for editing
                    editingMentionedContacts = loadedContacts
                    // Initialize reminder states
                    hasReminder = task.reminderTime != nil
                    editedReminderTime = task.reminderTime
                }
                // Don't focus automatically - let user tap to show keyboard
            } else if !isEditing {
                onTap()
            }
            // Don't handle tap in edit mode here - let the background gesture handle it
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // Only show swipe actions when not in edit mode, multi-select mode, or for completed tasks
            if !isEditing && !viewModel.isMultiSelectMode && !task.isCompleted {
                Button(role: .destructive) {
                    // If parent provided a delete handler, use it; otherwise show our own alert
                    if let onDeleteRequested = onDeleteRequested {
                        onDeleteRequested(task)
                    } else {
                        showingDeleteAlert = true
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .tint(.red)
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isEditing = true
                        onEditingChanged?(true, task)
                        // Initialize reminder states
                        hasReminder = task.reminderTime != nil
                        editedReminderTime = task.reminderTime
                    }
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            // Leading swipe action for quick complete
            if !isEditing && !viewModel.isMultiSelectMode && !task.isCompleted {
                Button {
                    print("✅ Completing task via swipe: \(task.title)")
                    viewModel.toggleTaskCompletion(task)
                } label: {
                    Label("Complete", systemImage: "checkmark.circle.fill")
                }
                .tint(.green)
            }
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
        .alert("Generation Error", isPresented: $showGenerationError) {
            Button("OK") {
                showGenerationError = false
            }
        } message: {
            Text(generationError ?? "Failed to generate checklist")
        }
        .sheet(isPresented: $showingCustomRecurrence) {
            CustomRecurrenceView(
                customRecurrence: $editedCustomRecurrence,
                isPresented: $showingCustomRecurrence
            )
            .onDisappear {
                // If custom recurrence was set, update the rule
                if editedCustomRecurrence != nil {
                    editedRecurrenceRule = .custom
                }
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                print("🗑️ Deleting task: \(task.title)")
                viewModel.deleteTask(task)
                // Don't call the callback here as this alert is only shown when there's no callback
            }
        } message: {
            Text("Are you sure you want to delete \"\(task.title)\"?")
        }

    }
    
    private var recurrenceDisplayText: String {
        if editedRecurrenceRule == .custom, let custom = editedCustomRecurrence {
            // Generate custom recurrence description
            var text = "Every "
            if custom.interval == 1 {
                text += "\(custom.unit.rawValue)"
            } else {
                text += "\(custom.interval) \(custom.unit.rawValue)s"
            }
            return text
        } else {
            return editedRecurrenceRule?.displayName ?? "Repeat"
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
                if !task.isCompleted && task.startedAt == nil {
                    // Start the task if not started
                    viewModel.startTask(task)
                } else {
                    // Toggle completion
                    viewModel.toggleTaskCompletion(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : 
                                task.startedAt != nil ? "play.circle.fill" : "circle")
                    .foregroundStyle(task.isCompleted ? .green : 
                                   task.startedAt != nil ? .blue : .secondary)
                    .font(.title3)
                    .contentTransition(.symbolEffect)
            }
            .buttonStyle(.plain)
            
            // Task content
            VStack(alignment: .leading, spacing: 4) {
                if !task.mentionedContactIds.isEmpty && !loadedContacts.isEmpty {
                    RichTextView(text: task.title, mentionedContacts: loadedContacts)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                } else {
                    Text(task.title)
                        .font(.body)
                        .strikethrough(task.isCompleted)
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                }
                
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
                    
                    if task.recurrenceRule != nil {
                        Label {
                            Text(task.recurrenceRule?.displayName ?? "Repeating")
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .font(.caption)
                        .foregroundStyle(.purple)
                    }
                    
                    if let duration = task.estimatedDuration {
                        Label {
                            Text(formatDuration(duration))
                        } icon: {
                            Image(systemName: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.orange)
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
             VStack(spacing: 12) {
                                 // Title Field
                 MentionableTextField(
                     text: $editedTitle,
                     mentionedContacts: $editingMentionedContacts,
                     placeholder: "Task Title"
                 )
                 .font(.body)
                 .textFieldStyle(.plain)
                 .padding(.horizontal, 12)
                 .padding(.vertical, 8)
                 .background(Color(.systemGray5))
                 .cornerRadius(8)
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
                 MentionableTextEditor(
                     text: $editedNotes,
                     mentionedContacts: $editingMentionedContacts,
                     placeholder: "Notes"
                 )
                 .font(.body)
                 .frame(minHeight: 60, maxHeight: 120)
                 .padding(8)
                 .background(Color(.systemGray5))
                 .cornerRadius(8)
                 .focused($isNotesFocused)
                     .onSubmit {
                         isTitleFocused = false
                         isNotesFocused = false
                         saveTask()
                     }
                
                // Metadata Grid - Two rows for better layout
                VStack(spacing: 8) {
                    // First Row: Priority, Date, Reminder Toggle
                    HStack(spacing: 8) {
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
                                if editedPriority != .none {
                                    Text(editedPriority.name)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        
                        // Date Picker
                        Menu {
                            Button("Today") { editedScheduledDate = Date() }
                            Button("Tomorrow") { editedScheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) }
                            Button("Next Week") { editedScheduledDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) }
                            Divider()
                            Button("Custom...") { showingDatePicker = true }
                            Divider()
                            Button("No Date", role: .destructive) { 
                                editedScheduledDate = nil
                                hasReminder = false
                                editedReminderTime = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .foregroundStyle(editedScheduledDate != nil ? .blue : .secondary)
                                if let date = editedScheduledDate {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                        .foregroundStyle(.primary)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        
                        // Reminder Toggle (only show if scheduled date is set)
                        if editedScheduledDate != nil {
                            HStack(spacing: 6) {
                                Image(systemName: hasReminder ? "bell.fill" : "bell")
                                    .foregroundStyle(hasReminder ? .blue : .secondary)
                                    .font(.caption)
                                
                                Toggle("", isOn: $hasReminder)
                                    .labelsHidden()
                                    .scaleEffect(0.8)
                                    .onChange(of: hasReminder) { _, enabled in
                                        if enabled {
                                            // Set default reminder time to 9 AM
                                            if editedReminderTime == nil {
                                                let calendar = Calendar.current
                                                var components = calendar.dateComponents([.year, .month, .day], from: editedScheduledDate!)
                                                components.hour = 9
                                                components.minute = 0
                                                editedReminderTime = calendar.date(from: components)
                                            }
                                        } else {
                                            editedReminderTime = nil
                                        }
                                    }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        
                        Spacer()
                    }
                    
                    // Second Row: Recurrence, Duration
                    HStack(spacing: 8) {
                        // Recurrence Picker
                        Menu {
                            Button("None") {
                                editedRecurrenceRule = nil
                                editedCustomRecurrence = nil
                            }
                            
                            Divider()
                            
                            ForEach(RecurrenceRule.allCases.filter { $0 != .custom }, id: \.self) { rule in
                                Button {
                                    editedRecurrenceRule = rule
                                    editedCustomRecurrence = nil
                                } label: {
                                    Label(rule.displayName, systemImage: rule.icon)
                                }
                            }
                            
                            Divider()
                            
                            Button {
                                showingCustomRecurrence = true
                            } label: {
                                Label("Custom...", systemImage: "gearshape")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: editedRecurrenceRule?.icon ?? "arrow.clockwise")
                                    .foregroundStyle(editedRecurrenceRule != nil ? .purple : .secondary)
                                if editedRecurrenceRule != nil {
                                    Text(recurrenceDisplayText)
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        
                        // Duration Picker
                        Menu {
                            Button("15 min") { editedDuration = 15 * 60 }
                            Button("30 min") { editedDuration = 30 * 60 }
                            Button("1 hour") { editedDuration = 60 * 60 }
                            Button("2 hours") { editedDuration = 2 * 60 * 60 }
                            Button("4 hours") { editedDuration = 4 * 60 * 60 }
                            Button("8 hours") { editedDuration = 8 * 60 * 60 }
                            
                            Divider()
                            
                            Button {
                                generateDurationEstimate()
                            } label: {
                                Label("AI Estimate", systemImage: "sparkles")
                            }
                            
                            Divider()
                            
                            Button("No Duration", role: .destructive) { editedDuration = nil }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .foregroundStyle(editedDuration != nil ? .orange : .secondary)
                                if isGeneratingDuration {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                } else {
                                    if editedDuration != nil {
                                        Text(durationDisplayText)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray5))
                            .cornerRadius(6)
                        }
                        .disabled(isGeneratingDuration)
                        
                        Spacer()
                    }
                }
                
                // Reminder Time Row (show when reminder is enabled)
                if hasReminder && editedScheduledDate != nil {
                    HStack {
                        Label("Reminder", systemImage: "bell.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        
                        Spacer()
                        
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { editedReminderTime ?? Date() },
                                set: { editedReminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(.blue)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .cornerRadius(8)
                }
                
                // Mentioned Contacts Section
                if !editingMentionedContacts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mentioned Contacts", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.indigo)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(editingMentionedContacts, id: \.identifier) { contact in
                                    HStack(spacing: 4) {
                                        InteractiveContactView(contact: contact, style: .mention)
                                        
                                        Button {
                                            editingMentionedContacts.removeAll { $0.identifier == contact.identifier }
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Checklist Section
                if !task.checklistItems.isEmpty || isGeneratingChecklist {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Label("Checklist", systemImage: "checklist")
                                .font(.caption)
                                .foregroundStyle(.green)
                            
                            if !task.checklistItems.isEmpty {
                                Text("\(task.checklistItems.filter { $0.isCompleted }.count)/\(task.checklistItems.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        // Checklist items
                        ForEach(task.checklistItems) { item in
                            HStack(spacing: 8) {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .font(.caption)
                                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                                    .onTapGesture {
                                        if let index = task.checklistItems.firstIndex(where: { $0.id == item.id }) {
                                            task.checklistItems[index].isCompleted.toggle()
                                        }
                                    }
                                
                                Text(item.title)
                                    .font(.caption)
                                    .strikethrough(item.isCompleted)
                                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                                
                                Spacer()
                            }
                        }
                        
                        // Add new item field
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.blue)
                            
                            TextField("Add checklist item", text: $newChecklistItem)
                                .font(.caption)
                                .textFieldStyle(.plain)
                                .focused($isNewChecklistItemFocused)
                                .onSubmit {
                                    addChecklistItem()
                                }
                        }
                    }
                }
                
                // AI Generate Checklist Button
                Button {
                    generateChecklist()
                } label: {
                    HStack(spacing: 6) {
                        if isGeneratingChecklist {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(task.checklistItems.isEmpty ? "Generate Checklist" : "Add More Items")
                    }
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .disabled(isGeneratingChecklist)
             }
             .padding(.horizontal, 16)
             .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
        .padding(.horizontal, 12)
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
        updatedTask.checklistItems = task.checklistItems // Save updated checklist items
        updatedTask.mentionedContactIds = editingMentionedContacts.map { $0.identifier }
        updatedTask.recurrenceRule = editedRecurrenceRule
        updatedTask.customRecurrence = editedCustomRecurrence
        updatedTask.estimatedDuration = editedDuration
        updatedTask.reminderTime = hasReminder ? editedReminderTime : nil
        
        // Clear custom recurrence if not using custom rule
        if editedRecurrenceRule != .custom {
            updatedTask.customRecurrence = nil
        }
        
        viewModel.updateTask(updatedTask)
        task = updatedTask
        
        // Dismiss keyboard
        isTitleFocused = false
        isNotesFocused = false
        isNewChecklistItemFocused = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditing = false
            onEditingChanged?(false, task)
            // Reload contacts after saving
            loadedContacts = editingMentionedContacts
            print("✅ Saved task with \(editingMentionedContacts.count) mentioned contacts")
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
    
    private func addChecklistItem() {
        guard !newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        task.checklistItems.append(ChecklistItem(title: newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)))
        newChecklistItem = ""
    }
    
    private func generateChecklist() {
        print("🎯 Starting AI checklist generation for task: \(task.title)")
        isGeneratingChecklist = true
        generationError = nil
        
        Task {
            do {
                let generatedItems = try await viewModel.generateTaskChecklist(for: task)
                
                await MainActor.run {
                    // Append generated items to existing checklist
                    task.checklistItems.append(contentsOf: generatedItems)
                    isGeneratingChecklist = false
                    print("✅ Successfully added \(generatedItems.count) AI-generated checklist items")
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    showGenerationError = true
                    isGeneratingChecklist = false
                    print("❌ Failed to generate checklist: \(error)")
                }
            }
        }
    }
    
    private var durationDisplayText: String {
        if let duration = editedDuration {
            return formatDuration(duration)
        } else {
            return "Duration"
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func generateDurationEstimate() {
        print("🤖 Starting AI duration estimation for task: \(task.title)")
        isGeneratingDuration = true
        
        Task {
            do {
                let estimatedDuration = try await viewModel.estimateTaskDuration(for: task)
                
                await MainActor.run {
                    editedDuration = estimatedDuration
                    isGeneratingDuration = false
                    print("✅ AI estimated duration: \(formatDuration(estimatedDuration))")
                    
                    // Store the AI estimation for learning
                    viewModel.recordDurationEstimation(
                        taskId: task.id,
                        aiEstimate: estimatedDuration,
                        taskTitle: task.title,
                        taskNotes: task.notes,
                        checklistCount: task.checklistItems.count
                    )
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    showGenerationError = true
                    isGeneratingDuration = false
                    print("❌ Failed to estimate duration: \(error)")
                }
            }
        }
    }
    
    private func loadMentionedContacts() {
        guard !task.mentionedContactIds.isEmpty else {
            loadedContacts = []
            return
        }
        
        Task {
            let store = CNContactStore()
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactImageDataKey,
                CNContactOrganizationNameKey,
                CNContactPhoneNumbersKey,
                CNContactEmailAddressesKey
            ] as [CNKeyDescriptor]
            
            var contacts: [CNContact] = []
            
            for contactId in task.mentionedContactIds {
                do {
                    let contact = try store.unifiedContact(withIdentifier: contactId, keysToFetch: keysToFetch)
                    contacts.append(contact)
                } catch {
                    print("❌ Failed to load contact with ID: \(contactId)")
                }
            }
            
            await MainActor.run {
                loadedContacts = contacts
                print("📱 Loaded \(contacts.count) contacts for task row")
            }
        }
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
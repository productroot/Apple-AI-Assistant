//
//  TaskRowView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI
import Contacts
import UniformTypeIdentifiers

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
    @State private var showingIntegratedDatePicker = false
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
    @State private var draggedChecklistItem: ChecklistItem?
    // Reminder state is now managed by the integrated picker
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
        // Reminder state is managed by the integrated picker
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
                    // Reminder time will be set by the integrated picker
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
                        // Reminder time will be set by the integrated picker
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
        .sheet(isPresented: $showingIntegratedDatePicker) {
            IntegratedDateReminderPicker(
                scheduledDate: $editedScheduledDate,
                reminderTime: $editedReminderTime
            )
            .presentationDetents([.large])
            .onDisappear {
                // Update hasReminder state based on whether reminder time was set
                // This ensures the reminder state is properly reflected
            }
        }
        .alert("Generation Error", isPresented: $showGenerationError) {
            Button("OK") {
                showGenerationError = false
            }
            #if os(iOS)
            if generationError?.contains("not available") == true {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
            #endif
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
            VStack(alignment: .leading, spacing: 8) {
                // Title
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
                
                // Notes (if present)
                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                // Metadata in same style as inline edit
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Priority
                        if task.priority != .none {
                            HStack(spacing: 6) {
                                Image(systemName: task.priority.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(task.priority.color)
                                Text(task.priority.name)
                                    .font(.caption)
                                    .foregroundStyle(task.priority.color)
                            }
                        }
                        
                        // Date & Reminder
                        if task.scheduledDate != nil {
                            Divider()
                                .frame(height: 20)
                            
                            HStack(spacing: 6) {
                                Image(systemName: task.reminderTime != nil ? "bell.badge" : "calendar")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                                if let date = task.scheduledDate {
                                    if let time = task.reminderTime {
                                        Text(time, format: .dateTime.month(.abbreviated).day().hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    } else {
                                        Text(date, format: .dateTime.month(.abbreviated).day())
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                        }
                        
                        // Recurrence
                        if let recurrenceRule = task.recurrenceRule {
                            Divider()
                                .frame(height: 20)
                            
                            HStack(spacing: 6) {
                                Image(systemName: recurrenceRule.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.purple)
                                Text(recurrenceRule.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                        
                        // Duration
                        if let duration = task.estimatedDuration {
                            Divider()
                                .frame(height: 20)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.orange)
                                Text(formatDuration(duration))
                                    .font(.caption)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .frame(height: 24)
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

    // Break down the complex view into smaller components
    @ViewBuilder
    private var titleEditSection: some View {
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
    }
    
    @ViewBuilder
    private var notesEditSection: some View {
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
    }
    
    @ViewBuilder
    private var metadataControlsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
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
                                HStack(spacing: 6) {
                                    Image(systemName: editedPriority.icon)
                                        .font(.system(size: 16))
                                        .foregroundStyle(editedPriority.color)
                                    if editedPriority != .none {
                                        Text(editedPriority.name)
                                            .font(.caption)
                                            .foregroundStyle(editedPriority.color)
                                    }
                                }
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
                            // Date & Reminder Picker
                            HStack(spacing: 6) {
                                Image(systemName: editedReminderTime != nil ? "bell.badge" : "calendar")
                                    .font(.system(size: 16))
                                    .foregroundStyle(editedScheduledDate != nil ? .blue : .secondary)
                                if let date = editedScheduledDate {
                                    if let time = editedReminderTime {
                                        Text(time, format: .dateTime.month(.abbreviated).day().hour().minute())
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    } else {
                                        Text(date, format: .dateTime.month(.abbreviated).day())
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                    }
                                }
                            }
                            .onTapGesture {
                                showingIntegratedDatePicker = true
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
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
                                HStack(spacing: 6) {
                                    Image(systemName: editedRecurrenceRule?.icon ?? "arrow.clockwise")
                                        .font(.system(size: 16))
                                        .foregroundStyle(editedRecurrenceRule != nil ? .purple : .secondary)
                                    if editedRecurrenceRule != nil {
                                        Text(recurrenceDisplayText)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            
                            Divider()
                                .frame(height: 20)
                            
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
                                HStack(spacing: 6) {
                                    Image(systemName: "clock")
                                        .font(.system(size: 16))
                                        .foregroundStyle(editedDuration != nil ? .orange : .secondary)
                                    if isGeneratingDuration {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else if let _ = editedDuration {
                                        Text(durationDisplayText)
                                            .font(.caption)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .disabled(isGeneratingDuration)
            }
            .padding(.horizontal, 4)
        }
        .frame(height: 30)
    }
    
    @ViewBuilder
    private var mentionedContactsSection: some View {
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
    }
    
    @ViewBuilder
    private var checklistItemsView: some View {
        VStack(spacing: 2) {
            ForEach(task.checklistItems.indices, id: \.self) { index in
                let item = task.checklistItems[index]
                InlineChecklistItemRow(
                    item: $task.checklistItems[index],
                    onDelete: {
                        withAnimation {
                            if index < task.checklistItems.count {
                                task.checklistItems.remove(at: index)
                                
                                // Save the updated task after deletion
                                var updatedTask = task
                                updatedTask.checklistItems = task.checklistItems
                                viewModel.updateTask(updatedTask)
                                print("💾 Deleted checklist item and saved task")
                            }
                        }
                    },
                    onChange: {
                        // Save the updated task after any change
                        var updatedTask = task
                        updatedTask.checklistItems = task.checklistItems
                        viewModel.updateTask(updatedTask)
                        print("💾 Updated checklist item and saved task")
                    },
                    draggedItem: $draggedChecklistItem
                )
                .background(draggedChecklistItem?.id == item.id ? Color.blue.opacity(0.1) : Color.clear)
                .onDrop(of: [.text], delegate: ChecklistDropDelegate(
                    item: item,
                    items: $task.checklistItems,
                    draggedItem: $draggedChecklistItem,
                    currentIndex: index,
                    onReorder: {
                        // Save the updated task after reordering
                        var updatedTask = task
                        updatedTask.checklistItems = task.checklistItems
                        viewModel.updateTask(updatedTask)
                        print("💾 Reordered checklist items and saved task")
                    }
                ))
            }
        }
    }
    
    @ViewBuilder
    private var checklistSection: some View {
        VStack(spacing: 8) {
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
                    checklistItemsView
                    
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
                    .padding(.top, 4)
                }
            }
            
            // AI Generate Checklist Button
            Button {
                print("🔘 Generate Checklist button tapped")
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
            .buttonStyle(.plain)
            .disabled(isGeneratingChecklist)
        }
    }
    
    private var expandedEditView: some View {
        VStack(spacing: 0) {
            // Main editing area
            VStack(spacing: 12) {
                // Title Field
                titleEditSection
                
                // Notes Field
                notesEditSection
                
                // Metadata Controls
                metadataControlsSection
                
                // Mentioned Contacts
                mentionedContactsSection
                
                // Checklist
                checklistSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                .onTapGesture {
                    // Only save if tapping the background, not on interactive elements
                    if !isTitleFocused && !isNotesFocused {
                        saveTask()
                    }
                }
        )
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
        updatedTask.reminderTime = editedReminderTime
        
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
    
    private func addChecklistItem() {
        guard !newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        task.checklistItems.append(ChecklistItem(title: newChecklistItem.trimmingCharacters(in: .whitespacesAndNewlines)))
        newChecklistItem = ""
        
        // Save the updated task to persist the new checklist item
        var updatedTask = task
        updatedTask.checklistItems = task.checklistItems
        viewModel.updateTask(updatedTask)
        print("💾 Added and saved new checklist item")
    }
    
    private func generateChecklist() {
        print("🎯 Starting AI checklist generation for task: \(task.title)")
        print("   Task ID: \(task.id)")
        print("   Current checklist items: \(task.checklistItems.count)")
        
        isGeneratingChecklist = true
        generationError = nil
        
        Task {
            do {
                print("📡 Calling viewModel.generateTaskChecklist...")
                let generatedItems = try await viewModel.generateTaskChecklist(for: task)
                print("📥 Received \(generatedItems.count) generated items")
                
                await MainActor.run {
                    // Append generated items to existing checklist
                    task.checklistItems.append(contentsOf: generatedItems)
                    isGeneratingChecklist = false
                    print("✅ Successfully added \(generatedItems.count) AI-generated checklist items")
                    
                    // Save the updated task to persist the new checklist items
                    var updatedTask = task
                    updatedTask.checklistItems = task.checklistItems
                    viewModel.updateTask(updatedTask)
                    print("💾 Saved updated task with new checklist items")
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    showGenerationError = true
                    isGeneratingChecklist = false
                    print("❌ Failed to generate checklist: \(error)")
                    print("   Error type: \(type(of: error))")
                    print("   Error details: \(error)")
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

// MARK: - Checklist Item Row
struct InlineChecklistItemRow: View {
    @Binding var item: ChecklistItem
    let onDelete: () -> Void
    let onChange: () -> Void
    @Binding var draggedItem: ChecklistItem?
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var deleteOffset: CGFloat = 0
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete button background
            HStack {
                Spacer()
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.white)
                        .frame(width: 60)
                }
                .frame(maxHeight: .infinity)
                .background(Color.red)
            }
            .opacity(deleteOffset < -60 ? 1 : 0)
            
            // Main content
            HStack(spacing: 8) {
                // Completion toggle
                Button {
                    item.isCompleted.toggle()
                    onChange()
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                
                // Item title
                if isEditing {
                    TextField("Item", text: $item.title)
                        .font(.caption)
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit {
                            isEditing = false
                            onChange()
                        }
                        .onChange(of: isFocused) { _, newValue in
                            if !newValue {
                                isEditing = false
                                onChange()
                            }
                        }
                } else {
                    Text(item.title)
                        .font(.caption)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isEditing = true
                            isFocused = true
                        }
                }
                
                Spacer()
                
                // Drag handle on the right
                Image(systemName: "line.3.horizontal")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
                    .onDrag {
                        draggedItem = item
                        return NSItemProvider(object: item.id.uuidString as NSString)
                    }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(6)
            .offset(x: deleteOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.width < 0 {
                            deleteOffset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if value.translation.width < -60 {
                                deleteOffset = -80
                            } else {
                                deleteOffset = 0
                            }
                        }
                    }
            )
        }
        .alert("Delete Item?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                withAnimation {
                    deleteOffset = 0
                }
            }
            Button("Delete", role: .destructive) {
                withAnimation {
                    onDelete()
                }
            }
        } message: {
            Text("Are you sure you want to delete \"\(item.title)\"?")
        }
    }
}

// MARK: - Draggable Checklist Preview
struct DraggableChecklistPreview: View {
    let item: ChecklistItem
    
    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.secondary)
            Text(item.title)
                .font(.caption)
        }
        .padding(8)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }
}

// MARK: - Checklist Drop Delegate
struct ChecklistDropDelegate: DropDelegate {
    let item: ChecklistItem
    @Binding var items: [ChecklistItem]
    @Binding var draggedItem: ChecklistItem?
    let currentIndex: Int
    let onReorder: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        onReorder()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != item.id,
              let from = items.firstIndex(where: { $0.id == draggedItem.id }),
              let to = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        withAnimation(.spring()) {
            items.move(fromOffsets: IndexSet(integer: from),
                      toOffset: to > from ? to + 1 : to)
        }
    }
    
    func dropExited(info: DropInfo) {
        // Optional: Add any cleanup here
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
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
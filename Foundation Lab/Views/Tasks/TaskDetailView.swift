//
//  TaskDetailView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI
import Contacts

struct TaskDetailView: View {
    @State var task: TodoTask
    var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var newChecklistItem = ""
    @State private var isGeneratingChecklist = false
    @State private var showGenerationError = false
    @State private var generationError: String?
    @State private var mentionedContacts: [CNContact] = []
    @State private var loadedContacts: [CNContact] = []
    @State private var hasReminder: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            MentionableTextField(
                                text: $task.title,
                                mentionedContacts: $mentionedContacts,
                                placeholder: "TodoTask Title"
                            )
                            .font(.title2)
                            .textFieldStyle(.roundedBorder)
                        } else {
                            HStack {
                                Button {
                                    task.isCompleted.toggle()
                                    task.completionDate = task.isCompleted ? Date() : nil
                                } label: {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                                }
                                .buttonStyle(.plain)
                                
                                Text(task.title)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .strikethrough(task.isCompleted)
                                
                                Spacer()
                            }
                        }
                        
                        // Metadata
                        HStack(spacing: 16) {
                            if task.priority != .none {
                                Label(task.priority.name, systemImage: task.priority.icon)
                                    .font(.caption)
                                    .foregroundStyle(task.priority.color)
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
                            
                            if let dueDate = task.dueDate {
                                Label {
                                    Text("Due \(dueDate, style: .date)")
                                } icon: {
                                    Image(systemName: "alarm")
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                            }
                            
                            if let reminderTime = task.reminderTime {
                                Label {
                                    Text(reminderTime, style: .time)
                                } icon: {
                                    Image(systemName: "bell.fill")
                                }
                                .font(.caption)
                                .foregroundStyle(.blue)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Date and Reminder Section (Edit Mode)
                    if isEditing {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Schedule")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                // Scheduled Date Toggle and Picker
                                HStack {
                                    Label("When", systemImage: "calendar")
                                    Spacer()
                                    if task.scheduledDate != nil {
                                        DatePicker(
                                            "",
                                            selection: Binding(
                                                get: { task.scheduledDate ?? Date() },
                                                set: { task.scheduledDate = $0 }
                                            ),
                                            displayedComponents: .date
                                        )
                                        .labelsHidden()
                                        
                                        Button {
                                            task.scheduledDate = nil
                                            task.reminderTime = nil
                                            hasReminder = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                                .font(.caption)
                                        }
                                    } else {
                                        Button("Set Date") {
                                            task.scheduledDate = Date()
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Reminder Time Picker
                                ReminderTimePicker(
                                    reminderTime: $task.reminderTime,
                                    hasReminder: $hasReminder,
                                    scheduledDate: task.scheduledDate
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 8)
                    }
                    
                    // Notes Section
                    if isEditing || !task.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isEditing {
                                MentionableTextEditor(
                                    text: $task.notes,
                                    mentionedContacts: $mentionedContacts,
                                    placeholder: "Add notes..."
                                )
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            } else {
                                Text(task.notes)
                                    .padding(.horizontal)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Mentioned Contacts Section
                    if !loadedContacts.isEmpty || (isEditing && !mentionedContacts.isEmpty) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Mentioned Contacts")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(isEditing ? mentionedContacts : loadedContacts, id: \.identifier) { contact in
                                        InteractiveContactView(contact: contact, style: .mention)
                                        
                                        if isEditing {
                                            Button {
                                                mentionedContacts.removeAll { $0.identifier == contact.identifier }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.secondary)
                                                    .font(.caption)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Recurrence Section
                    if isEditing || task.recurrenceRule != nil {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isEditing {
                                Menu {
                                    Button("None") {
                                        task.recurrenceRule = nil
                                        task.customRecurrence = nil
                                    }
                                    
                                    Divider()
                                    
                                    ForEach(RecurrenceRule.allCases.filter { $0 != .custom }, id: \.self) { rule in
                                        Button {
                                            task.recurrenceRule = rule
                                            task.customRecurrence = nil
                                        } label: {
                                            Label(rule.displayName, systemImage: rule.icon)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Label {
                                            Text(task.recurrenceRule?.displayName ?? "None")
                                        } icon: {
                                            Image(systemName: task.recurrenceRule?.icon ?? "arrow.clockwise")
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                                .padding(.horizontal)
                            } else if let recurrenceRule = task.recurrenceRule {
                                Label {
                                    Text("Repeats \(recurrenceRule.displayName)")
                                } icon: {
                                    Image(systemName: recurrenceRule.icon)
                                }
                                .padding(.horizontal)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    // Checklist Section
                    if isEditing || !task.checklistItems.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Checklist")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if isEditing {
                                    Button {
                                        generateChecklist()
                                    } label: {
                                        HStack(spacing: 4) {
                                            if isGeneratingChecklist {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                            } else {
                                                Image(systemName: "sparkles")
                                            }
                                            Text("Generate")
                                                .font(.caption)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    .disabled(isGeneratingChecklist)
                                }
                                
                                if !task.checklistItems.isEmpty {
                                    Text("\(task.checklistItems.filter { $0.isCompleted }.count)/\(task.checklistItems.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach($task.checklistItems) { $item in
                                    ChecklistItemRow(item: $item, isEditing: isEditing, onDelete: {
                                        task.checklistItems.removeAll { $0.id == item.id }
                                    })
                                }
                                
                                if isEditing {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(.blue)
                                        
                                        TextField("Add item", text: $newChecklistItem)
                                            .onSubmit {
                                                addChecklistItem()
                                            }
                                    }
                                    .padding()
                                }
                            }
                        }
                    }
                    
                    // Tags Section
                    if !task.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(Array(task.tags), id: \.self) { tag in
                                    TagChip(tag: tag)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("TodoTask Details")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadMentionedContacts()
                hasReminder = task.reminderTime != nil
            }
            .onChange(of: isEditing) { oldValue, newValue in
                if newValue {
                    mentionedContacts = loadedContacts
                    hasReminder = task.reminderTime != nil
                } else {
                    loadMentionedContacts()
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            dismiss()
                        }
                    } else {
                        Button("Done") {
                            viewModel.updateTask(task)
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            task.mentionedContactIds = mentionedContacts.map { $0.identifier }
                            if !hasReminder {
                                task.reminderTime = nil
                            }
                            viewModel.updateTask(task)
                            isEditing = false
                            print("✅ Saved task with \(mentionedContacts.count) mentioned contacts")
                        }
                    } else {
                        Menu {
                            Button {
                                isEditing = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Delete Task?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    viewModel.deleteTask(task)
                    dismiss()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Generation Error", isPresented: $showGenerationError) {
                Button("OK") {
                    showGenerationError = false
                }
            } message: {
                Text(generationError ?? "Failed to generate checklist")
            }
        }
    }
    
    private func addChecklistItem() {
        guard !newChecklistItem.isEmpty else { return }
        task.checklistItems.append(ChecklistItem(title: newChecklistItem))
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
    
    private func loadMentionedContacts() {
        guard !task.mentionedContactIds.isEmpty else {
            loadedContacts = []
            return
        }
        
        print("📱 Loading \(task.mentionedContactIds.count) mentioned contacts")
        
        Task {
            let store = CNContactStore()
            let keysToFetch = [
                CNContactGivenNameKey,
                CNContactFamilyNameKey,
                CNContactEmailAddressesKey,
                CNContactPhoneNumbersKey,
                CNContactImageDataKey,
                CNContactOrganizationNameKey
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
                print("✅ Loaded \(contacts.count) contacts")
            }
        }
    }
}

// MARK: - Checklist Item Row
struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    let isEditing: Bool
    let onDelete: (() -> Void)?
    
    init(item: Binding<ChecklistItem>, isEditing: Bool, onDelete: (() -> Void)? = nil) {
        self._item = item
        self.isEditing = isEditing
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack {
            Button {
                item.isCompleted.toggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            if isEditing {
                TextField("Item", text: $item.title)
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
            }
            
            Spacer()
            
            if isEditing, let onDelete = onDelete {
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .cornerRadius(16)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let dimensions = subview.dimensions(in: .unspecified)
                
                if x + dimensions.width > maxWidth && x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                x += dimensions.width + spacing
                maxHeight = max(maxHeight, dimensions.height)
            }
            
            size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}
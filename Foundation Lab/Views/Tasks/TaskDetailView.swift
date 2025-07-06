//
//  TaskDetailView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TaskDetailView: View {
    @State var task: TodoTask
    @Binding var viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    @State private var newChecklistItem = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Title Section
                    VStack(alignment: .leading, spacing: 8) {
                        if isEditing {
                            TextField("TodoTask Title", text: $task.title)
                                .font(.title2)
                                .textFieldStyle(.roundedBorder)
                        } else {
                            HStack {
                                Button {
                                    task.isCompleted.toggle()
                                    task.completedDate = task.isCompleted ? Date() : nil
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
                                Label(task.priority.name, systemImage: "flag.fill")
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
                        }
                    }
                    .padding(.horizontal)
                    
                    // Notes Section
                    if isEditing || !task.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if isEditing {
                                TextEditor(text: $task.notes)
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
                    
                    // Checklist Section
                    if isEditing || !task.checklist.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Checklist")
                                    .font(.headline)
                                
                                Spacer()
                                
                                if !task.checklist.isEmpty {
                                    Text("\(task.checklist.filter { $0.isCompleted }.count)/\(task.checklist.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 0) {
                                ForEach($task.checklist) { $item in
                                    ChecklistItemRow(item: $item, isEditing: isEditing)
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
                            viewModel.updateTask(task)
                            isEditing = false
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
        }
    }
    
    private func addChecklistItem() {
        guard !newChecklistItem.isEmpty else { return }
        task.checklist.append(ChecklistItem(title: newChecklistItem))
        newChecklistItem = ""
    }
}

// MARK: - Checklist Item Row
struct ChecklistItemRow: View {
    @Binding var item: ChecklistItem
    let isEditing: Bool
    
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
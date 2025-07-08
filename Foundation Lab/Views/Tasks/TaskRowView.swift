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

    @State private var isEditing = false
    @State private var editedTitle: String

    init(task: TodoTask, viewModel: TasksViewModel, isSelected: Bool, onTap: @escaping () -> Void) {
        _task = State(initialValue: task)
        self.viewModel = viewModel
        self.isSelected = isSelected
        self.onTap = onTap
        _editedTitle = State(initialValue: task.title)
    }

    var body: some View {
        HStack(spacing: 12) {
            if isEditing {
                editView
            } else {
                displayView
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isEditing && !task.isCompleted {
                isEditing = true
            }
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
                        Image(systemName: "flag.fill")
                            .font(.caption2)
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
    }

    private var editView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Task Title", text: $editedTitle)
                .textFieldStyle(.plain)
                .font(.body)

            HStack(spacing: 16) {
                // Date Picker
                Menu {
                    Button("Today") { task.scheduledDate = Date() }
                    Button("Tomorrow") { task.scheduledDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) }
                    Button("Next Week") { task.scheduledDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) }
                    Divider()
                    Button("No Date", role: .destructive) { task.scheduledDate = nil }
                } label: {
                    Image(systemName: "calendar")
                }

                // Priority Picker
                Menu {
                    ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                        Button(priority.name) { task.priority = priority }
                    }
                } label: {
                    Image(systemName: "flag")
                }

                Spacer()

                Button("Cancel") {
                    editedTitle = task.title
                    isEditing = false
                }
                .buttonStyle(.borderless)

                Button("Save") {
                    var updatedTask = task
                    updatedTask.title = editedTitle
                    viewModel.updateTask(updatedTask)
                    isEditing = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
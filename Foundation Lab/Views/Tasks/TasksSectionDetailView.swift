//
//  TasksSectionDetailView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TasksSectionDetailView: View {
    @Binding var viewModel: TasksViewModel
    let filter: TaskFilter
    @State private var showingAddTask = false
    @State private var selectedTask: TodoTask?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredTasks) { task in
                    TaskRowView(
                        task: task,
                        viewModel: $viewModel,
                        isSelected: viewModel.selectedTasks.contains(task.id),
                        onTap: {
                            if viewModel.isMultiSelectMode {
                                toggleSelection(for: task)
                            } else {
                                selectedTask = task
                            }
                        }
                    )
                    .onDrag {
                        NSItemProvider(object: task.id.uuidString as NSString)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .overlay(alignment: .bottomTrailing) {
            magicPlusButton
                .padding()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: $viewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: $viewModel)
        }
    }
    
    private var filteredTasks: [TodoTask] {
        viewModel.selectedFilter = filter
        return viewModel.filteredTasks
    }
    
    private var navigationTitle: String {
        switch filter {
        case .section(let section):
            return section.rawValue
        case .area(let area):
            return area.name
        case .project(let project):
            return project.name
        case .tag(let tag):
            return "#\(tag)"
        default:
            return "Tasks"
        }
    }
    
    private func toggleSelection(for task: TodoTask) {
        if viewModel.selectedTasks.contains(task.id) {
            viewModel.selectedTasks.remove(task.id)
        } else {
            viewModel.selectedTasks.insert(task.id)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        ToolbarItem(placement: .secondaryAction) {
            Menu {
                ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                    Button {
                        // Filter by priority
                    } label: {
                        Label(priority.name, systemImage: "flag.fill")
                            .foregroundStyle(priority.color)
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
            }
        }
        
        if viewModel.isMultiSelectMode {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    viewModel.isMultiSelectMode = false
                    viewModel.selectedTasks.removeAll()
                }
            }
            
            if !viewModel.selectedTasks.isEmpty {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            viewModel.deleteTasks(viewModel.selectedTasks)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .foregroundStyle(.red)
                        
                        Spacer()
                        
                        Text("\(viewModel.selectedTasks.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var magicPlusButton: some View {
        Button {
            showingAddTask = true
        } label: {
            ZStack {
                Circle()
                    .fill(.blue)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                
                Image(systemName: "plus")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
        .sensoryFeedback(.impact, trigger: showingAddTask)
        .draggable("newTask") {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue.opacity(0.2))
                    .frame(width: 200, height: 44)
                
                Text("New Task")
                    .font(.caption)
            }
        }
    }
}
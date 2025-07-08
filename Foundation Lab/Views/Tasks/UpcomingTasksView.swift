//
//  UpcomingTasksView.swift
//  FoundationLab
//
//  Created by Assistant on 12/30/24.
//

import SwiftUI

struct UpcomingTasksView: View {
    let viewModel: TasksViewModel
    @State private var showingAddTask = false
    @State private var selectedTask: TodoTask?
    @State private var editingTask: TodoTask?
    @State private var showingDeleteTaskAlert = false
    @State private var showingMoveSheet = false
    @State private var shouldSaveEditingTask = false
    
    private var groupedTasks: [(Date, [TodoTask])] {
        let tasks = viewModel.upcomingTasks.sorted { $0.scheduledDate ?? Date() < $1.scheduledDate ?? Date() }
        
        let grouped = Dictionary(grouping: tasks) { task in
            let calendar = Calendar.current
            if let scheduledDate = task.scheduledDate {
                return calendar.startOfDay(for: scheduledDate)
            }
            return calendar.startOfDay(for: Date())
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ZStack {
            // Background tap area
            if editingTask != nil {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeEditingMode()
                    }
                    .zIndex(0)
            }
            
            Group {
                if groupedTasks.isEmpty {
                    emptyState
                } else {
                    tasksList
                }
            }
            .zIndex(1)
            
            // Floating action button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    Button(action: {
                        showingAddTask = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("Upcoming")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: viewModel)
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let task = editingTask {
                TaskMoveView(task: task, viewModel: viewModel) {
                    showingMoveSheet = false
                    editingTask = nil
                }
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteTaskAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let task = editingTask {
                    viewModel.deleteTask(task)
                    editingTask = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this task?")
        }
        .overlay(alignment: .bottom) {
            if let editingTask = editingTask {
                TaskEditToolbar(
                    task: editingTask,
                    viewModel: viewModel,
                    onMoveRequested: {
                        showingMoveSheet = true
                    },
                    onDeleteRequested: {
                        showingDeleteTaskAlert = true
                    },
                    onDuplicateRequested: {
                        duplicateTask(editingTask)
                    }
                )
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                Text("No Upcoming Tasks")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("Tasks scheduled for future dates will appear here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var tasksList: some View {
        List {
            ForEach(groupedTasks, id: \.0) { date, tasks in
                Section {
                    ForEach(tasks) { task in
                        TaskRowView(
                            task: task,
                            viewModel: viewModel,
                            isSelected: viewModel.selectedTasks.contains(task.id),
                            onTap: {
                                if viewModel.isMultiSelectMode {
                                    toggleSelection(for: task)
                                } else {
                                    selectedTask = task
                                }
                            },
                            onEditingChanged: { isEditing, task in
                                editingTask = isEditing ? task : nil
                                if !isEditing {
                                    shouldSaveEditingTask = false
                                }
                            },
                            onMoveRequested: { task in
                                editingTask = task
                                showingMoveSheet = true
                            },
                            onDeleteRequested: { task in
                                editingTask = task
                                showingDeleteTaskAlert = true
                            },
                            onDuplicateRequested: { task in
                                duplicateTask(task)
                            },
                            shouldSaveFromParent: shouldSaveEditingTask && editingTask?.id == task.id
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                } header: {
                    DayHeaderView(date: date)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Helper Methods
    private func toggleSelection(for task: TodoTask) {
        if viewModel.selectedTasks.contains(task.id) {
            viewModel.selectedTasks.remove(task.id)
        } else {
            viewModel.selectedTasks.insert(task.id)
        }
    }
    
    private func duplicateTask(_ task: TodoTask) {
        var newTask = task
        newTask.id = UUID()
        newTask.title = "Copy of \(task.title)"
        newTask.isCompleted = false
        newTask.completionDate = nil
        newTask.createdAt = Date()
        viewModel.addTask(newTask)
        editingTask = nil
    }
    
    private func closeEditingMode() {
        if let task = editingTask {
            shouldSaveEditingTask = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                editingTask = nil
                shouldSaveEditingTask = false
            }
        }
    }
}

struct DayHeaderView: View {
    let date: Date
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    private var dayName: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        if calendar.isDate(date, inSameDayAs: today) {
            return "Today"
        } else if calendar.isDate(date, inSameDayAs: tomorrow) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Day number - large and prominent
            Text(dayNumber)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.primary)
                .frame(minWidth: 44)
            
            // Day name
            Text(dayName)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .textCase(nil)
    }
}

#Preview {
    NavigationStack {
        UpcomingTasksView(viewModel: TasksViewModel())
    }
} 
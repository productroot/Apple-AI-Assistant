//
//  TasksView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TasksView: View {
    @Binding var viewModel: TasksViewModel
    @State private var showingAddTask = false
    @State private var selectedTask: TodoTask?
    @State private var draggedTasks: Set<UUID> = []
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            #if os(iOS)
            if horizontalSizeClass == .compact {
                compactLayout
            } else {
                regularLayout
            }
            #else
            regularLayout
            #endif
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: $viewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: $viewModel)
        }
    }
    
    // MARK: - Compact Layout (iPhone)
    private var compactLayout: some View {
        NavigationStack {
            TaskListView(
                tasks: viewModel.filteredTasks,
                viewModel: $viewModel,
                selectedTask: $selectedTask
            )
            .navigationTitle(navigationTitle)
            .toolbar {
                toolbarContent
            }
            .overlay(alignment: .bottomTrailing) {
                magicPlusButton
                    .padding()
            }
        }
    }
    
    // MARK: - Regular Layout (iPad/Mac)
    private var regularLayout: some View {
        NavigationSplitView {
            TaskSidebarView(viewModel: $viewModel)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            TaskListView(
                tasks: viewModel.filteredTasks,
                viewModel: $viewModel,
                selectedTask: $selectedTask
            )
            .navigationTitle(navigationTitle)
            .toolbar {
                toolbarContent
            }
            .overlay(alignment: .bottomTrailing) {
                magicPlusButton
                    .padding()
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Navigation Title
    private var navigationTitle: String {
        switch viewModel.selectedFilter {
        case .all:
            return "All TodoTasks"
        case .section(let section):
            return section.rawValue
        case .area(let area):
            return area.name
        case .project(let project):
            return project.name
        case .tag(let tag):
            return "#\(tag)"
        case .search(let query):
            return "Search: \(query)"
        }
    }
    
    // MARK: - Toolbar Content
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
    
    // MARK: - Magic Plus Button
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
        .draggable("newTodoTask") {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.blue.opacity(0.2))
                    .frame(width: 200, height: 44)
                
                Text("New TodoTask")
                    .font(.caption)
            }
        }
    }
}

// MARK: - TodoTask List View
struct TaskListView: View {
    let tasks: [TodoTask]
    @Binding var viewModel: TasksViewModel
    @Binding var selectedTask: TodoTask?
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(tasks) { task in
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
    }
    
    private func toggleSelection(for task: TodoTask) {
        if viewModel.selectedTasks.contains(task.id) {
            viewModel.selectedTasks.remove(task.id)
        } else {
            viewModel.selectedTasks.insert(task.id)
        }
    }
}

// MARK: - TodoTask Row View
struct TaskRowView: View {
    let task: TodoTask
    @Binding var viewModel: TasksViewModel
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
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
            
            // TodoTask content
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
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - TodoTask Sidebar View
struct TaskSidebarView: View {
    @Binding var viewModel: TasksViewModel
    
    var body: some View {
        List {
            // Sections
            Section {
                ForEach(TaskSection.allCases, id: \.self) { section in
                    Button {
                        viewModel.selectedFilter = .section(section)
                    } label: {
                        Label {
                            HStack {
                                Text(section.rawValue)
                                Spacer()
                                if taskCount(for: section) > 0 {
                                    Text("\(taskCount(for: section))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } icon: {
                            Image(systemName: section.icon)
                                .foregroundStyle(section.color)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Areas
            if !viewModel.areas.isEmpty {
                Section("Areas") {
                    ForEach(viewModel.areas) { area in
                        Button {
                            viewModel.selectedFilter = .area(area)
                        } label: {
                            Label {
                                Text(area.name)
                            } icon: {
                                Image(systemName: area.icon)
                                    .foregroundStyle(area.color)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Projects
            if !viewModel.projects.isEmpty {
                Section("Projects") {
                    ForEach(viewModel.projects) { project in
                        Button {
                            viewModel.selectedFilter = .project(project)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(project.color)
                                    .frame(width: 8, height: 8)
                                
                                Text(project.name)
                                
                                Spacer()
                                
                                if project.progress > 0 {
                                    CircularProgressView(progress: project.progress)
                                        .frame(width: 20, height: 20)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
    
    private func taskCount(for section: TaskSection) -> Int {
        switch section {
        case .inbox:
            return viewModel.tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId == nil }.count
        case .today:
            return viewModel.todayTasks.count
        case .upcoming:
            return viewModel.upcomingTasks.count
        case .anytime:
            return viewModel.tasks.filter { !$0.isCompleted && $0.scheduledDate == nil && $0.projectId != nil }.count
        case .someday:
            return viewModel.tasks.filter { !$0.isCompleted && $0.tags.contains("someday") }.count
        case .logbook:
            return viewModel.tasks.filter { $0.isCompleted }.count
        }
    }
}

// MARK: - Circular Progress View
struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
        }
    }
}

#Preview {
    TasksView(viewModel: .constant(TasksViewModel()))
}
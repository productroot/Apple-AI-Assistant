//
//  TasksSectionDetailView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TasksSectionDetailView: View {
    var viewModel: TasksViewModel
    let filter: TaskFilter
    @State private var showingAddTask = false
    @State private var selectedTask: TodoTask?
    @State private var showingDeleteAlert = false
    @State private var showCompleted = false
    @State private var expandedProjects: Set<UUID> = []
    @State private var editingTask: TodoTask?
    @State private var showingMoveSheet = false
    @State private var showingDeleteTaskAlert = false
    @State private var shouldSaveEditingTask = false
    @State private var showingProjectDeadlineSheet = false
    @State private var showingProjectMoveSheet = false
    @State private var projectToEdit: Project?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Group {
            if case .section(let section) = filter, section == .anytime {
                anytimeBody
            } else if case .section(let section) = filter, section == .today {
                todayBody
            } else if case .section(let section) = filter, section == .upcoming {
                upcomingBody
            } else if case .section(let section) = filter, section == .logbook {
                logbookBody
            } else {
                defaultBody
                    .onAppear {
                        print("🔧 defaultBody appeared, filter: \(String(describing: filter))")
                    }
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent
        }
        .overlay(alignment: .bottomTrailing) {
            if editingTask == nil {
                magicPlusButton
                    .padding()
            }
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


        .sheet(isPresented: $showingAddTask) {
            AddTaskView(viewModel: viewModel)
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(task: task, viewModel: viewModel)
        }
        .alert("Delete Project", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if case .project(let project) = filter {
                    viewModel.deleteProject(project)
                    dismiss()
                }
            }
        } message: {
            if case .project(let project) = filter {
                Text("Are you sure you want to delete \"\(project.name)\"? This will also delete all tasks in this project.")
            }
        }
        .alert("Delete Task", isPresented: $showingDeleteTaskAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let editingTask = editingTask {
                    viewModel.deleteTask(editingTask)
                    self.editingTask = nil
                }
            }
        } message: {
            if let editingTask = editingTask {
                Text("Are you sure you want to delete \"\(editingTask.title)\"?")
            }
        }
        .sheet(isPresented: $showingMoveSheet) {
            if let editingTask = editingTask {
                TaskMoveView(task: editingTask, viewModel: viewModel) {
                    self.editingTask = nil
                }
            }
        }
        .sheet(isPresented: $showingProjectDeadlineSheet) {
            if case .project(let project) = filter {
                ProjectDeadlineSheet(project: project, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingProjectMoveSheet) {
            if case .project(let project) = filter {
                ProjectMoveSheet(project: project, viewModel: viewModel)
            }
        }
        .sheet(item: $projectToEdit) { project in
            EditProjectView(viewModel: viewModel, project: project)
        }
    }

    @ViewBuilder
    private var todayBody: some View {
        List {
            let todayTasks = viewModel.todayTasks
            let tasksWithoutProject = todayTasks.filter { $0.projectId == nil }
            
            if todayTasks.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Tasks Today")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("Tasks scheduled for today or overdue will appear here.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                // Tasks without projects
                if !tasksWithoutProject.isEmpty {
                    Section {
                        ForEach(tasksWithoutProject) { task in
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
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            .onDrag {
                                NSItemProvider(object: task.id.uuidString as NSString)
                            }
                        }
                    }
                }
                
                // Tasks grouped by project
                ForEach(viewModel.todayTasksByProject.keys.sorted(by: { $0.name < $1.name }), id: \.self) { project in
                    Section {
                        // Project header with task count
                        ProjectHeaderView(
                            project: project,
                            viewModel: viewModel,
                            taskCount: viewModel.todayTasksByProject[project]?.count ?? 0
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        
                        // Active tasks
                        ForEach(viewModel.todayTasksByProject[project] ?? []) { task in
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
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            .onDrag {
                                NSItemProvider(object: task.id.uuidString as NSString)
                            }
                        }
                        
                        // Completed tasks section (only tasks completed today)
                        let completedTasks = completedTasksForProjectToday(project)
                        if !completedTasks.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedProjects.contains(project.id) {
                                        expandedProjects.remove(project.id)
                                    } else {
                                        expandedProjects.insert(project.id)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(expandedProjects.contains(project.id) ? "Hide Completed" : "Show \(completedTasks.count) Completed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .rotationEffect(.degrees(expandedProjects.contains(project.id) ? 90 : 0))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 4, leading: 32, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            
                            if expandedProjects.contains(project.id) {
                                ForEach(completedTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        viewModel: viewModel,
                                        isSelected: false,
                                        onTap: { selectedTask = task }
                                    )
                                    .listRowInsets(EdgeInsets(top: 2, leading: 32, bottom: 2, trailing: 16))
                                    .opacity(0.7)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentShape(Rectangle())
        .onTapGesture {
            closeEditingMode()
        }
    }

    @ViewBuilder
    private var anytimeBody: some View {
        List {
            if viewModel.anytimeTasksByProject.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "square.stack")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Anytime Tasks")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("All open tasks that belong to projects will appear here.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        showingAddTask = true
                    } label: {
                        Label("Add Task", systemImage: "plus")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.anytimeTasksByProject.keys.sorted(by: { $0.name < $1.name }), id: \.self) { project in
                    Section {
                        // Project header with task count
                        ProjectHeaderView(
                            project: project,
                            viewModel: viewModel,
                            taskCount: viewModel.anytimeTasksByProject[project]?.count ?? 0
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        
                        // Active tasks
                        ForEach(viewModel.anytimeTasksByProject[project] ?? []) { task in
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
                            .listRowInsets(EdgeInsets(top: 2, leading: 16, bottom: 2, trailing: 16))
                            .onDrag {
                                NSItemProvider(object: task.id.uuidString as NSString)
                            }
                        }
                        
                        // Completed tasks section
                        let completedTasks = completedTasksForProject(project)
                        if !completedTasks.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if expandedProjects.contains(project.id) {
                                        expandedProjects.remove(project.id)
                                    } else {
                                        expandedProjects.insert(project.id)
                                    }
                                }
                            }) {
                                HStack {
                                    Text(expandedProjects.contains(project.id) ? "Hide Completed" : "Show \(completedTasks.count) Completed")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                        .rotationEffect(.degrees(expandedProjects.contains(project.id) ? 90 : 0))
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 4, leading: 32, bottom: 4, trailing: 16))
                            .listRowBackground(Color.clear)
                            
                            if expandedProjects.contains(project.id) {
                                ForEach(completedTasks) { task in
                                    TaskRowView(
                                        task: task,
                                        viewModel: viewModel,
                                        isSelected: false,
                                        onTap: { selectedTask = task }
                                    )
                                    .listRowInsets(EdgeInsets(top: 2, leading: 32, bottom: 2, trailing: 16))
                                    .opacity(0.7)
                                }
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .contentShape(Rectangle())
        .onTapGesture {
            closeEditingMode()
        }
    }
    
    private var upcomingBody: some View {
        UpcomingTasksView(viewModel: viewModel)
    }
    
    private var logbookBody: some View {
        List {
            ForEach(logbookTasks) { task in
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
                .onDrag {
                    NSItemProvider(object: task.id.uuidString as NSString)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            // Show empty state if no completed tasks
            if logbookTasks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("No Completed Tasks")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text("Completed tasks will appear here.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 80)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            closeEditingMode()
        }
    }
    
    // MARK: - Helper Methods
    private func completedTasksForProject(_ project: Project) -> [TodoTask] {
        return viewModel.tasks.filter { $0.isCompleted && $0.projectId == project.id }
    }
    
    private func completedTasksForProjectToday(_ project: Project) -> [TodoTask] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return viewModel.tasks.filter { task in
            task.isCompleted && 
            task.projectId == project.id &&
            task.completionDate != nil &&
            task.completionDate! >= today &&
            task.completionDate! < endOfToday
        }
    }

    @ViewBuilder
    private var defaultBody: some View {
        List {
            ForEach(filteredTasks) { task in
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
                .onDrag {
                    NSItemProvider(object: task.id.uuidString as NSString)
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }

            if !completedTasks.isEmpty {
                completedTasksSection
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .contentShape(Rectangle())
        .onTapGesture {
            closeEditingMode()
        }
    }

    @ViewBuilder
    private var completedTasksSection: some View {
        Section {
            Button(action: { showCompleted.toggle() }) {
                HStack {
                    Text(showCompleted ? "Hide Completed Tasks" : "Show \(completedTasks.count) Completed Tasks")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showCompleted ? 90 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding()

            if showCompleted {
                ForEach(completedTasks) { task in
                    TaskRowView(
                        task: task,
                        viewModel: viewModel,
                        isSelected: false,
                        onTap: { selectedTask = task }
                    )
                }
            }
        }
    }
    
    private var filteredTasks: [TodoTask] {
        viewModel.selectedFilter = filter
        return viewModel.filteredTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [TodoTask] {
        viewModel.selectedFilter = filter
        return viewModel.filteredTasks.filter { $0.isCompleted }
    }
    
    private var logbookTasks: [TodoTask] {
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
    
    private func duplicateTask(_ task: TodoTask) {
        let duplicatedTask = TodoTask(
            title: "\(task.title) (Copy)",
            notes: task.notes,
            tags: task.tags,
            dueDate: task.dueDate,
            scheduledDate: task.scheduledDate,
            projectId: task.projectId,
            areaId: task.areaId,
            priority: task.priority
        )
        
        viewModel.addTask(duplicatedTask)
        editingTask = nil
    }
    
    private func closeEditingMode() {
        // Trigger save in the currently editing task
        if editingTask != nil {
            shouldSaveEditingTask = true
            
            // Close editing mode after a brief delay to allow save to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    editingTask = nil
                    shouldSaveEditingTask = false
                }
            }
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
        
        // Combined menu for project actions and filters
        if case .project(let project) = filter {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section {
                        Button {
                            projectToEdit = project
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button {
                            // TODO: Implement When functionality
                        } label: {
                            Label("When", systemImage: "calendar")
                        }
                        
                        Button {
                            showingProjectDeadlineSheet = true
                        } label: {
                            Label("Set Deadline", systemImage: "flag")
                        }
                        
                        Button {
                            showingProjectMoveSheet = true
                        } label: {
                            Label("Move", systemImage: "arrow.right")
                        }
                    }
                    
                    Section {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Project", systemImage: "trash")
                        }
                    }
                    
                    Section("Filter by Priority") {
                        ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                            Button {
                                // TODO: Implement priority filtering
                            } label: {
                                Label(priority.name, systemImage: priority.icon)
                                    .foregroundStyle(priority.color)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        } else {
            // For non-project views, just show the filter
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                        Button {
                            // TODO: Implement priority filtering
                        } label: {
                            Label(priority.name, systemImage: priority.icon)
                                .foregroundStyle(priority.color)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
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
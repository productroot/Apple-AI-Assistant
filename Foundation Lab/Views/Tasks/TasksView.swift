//
//  TasksView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI

struct TasksView: View {
    let viewModel: TasksViewModel
    @State private var navigationPath = NavigationPath()
    @State private var showingAddTask = false
    @State private var showingQuickAddOverlay = false
    @State private var isCreatingProject = false
    @State private var newProjectName = ""
    @State private var newProjectAreaId: UUID?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        ZStack {
            NavigationStack(path: $navigationPath) {
            List {
                // Main Sections
                Section {
                    ForEach(TaskSection.allCases.filter { $0 != .logbook }, id: \.self) { section in
                        NavigationLink(value: TaskFilter.section(section)) {
                            TaskSectionRow(
                                section: section,
                                count: taskCount(for: section),
                                viewModel: viewModel
                            )
                        }
                    }
                }
                
                // Logbook Section (separated)
                Section {
                    NavigationLink(value: TaskFilter.section(.logbook)) {
                        TaskSectionRow(
                            section: .logbook,
                            count: taskCount(for: .logbook),
                            viewModel: viewModel
                        )
                    }
                }
                
                // Areas & Projects
                if !viewModel.areas.isEmpty {
                    ForEach(viewModel.areas) { area in
                        Section(header: AreaHeaderView(area: area)) {
                            // Area tasks
                            NavigationLink(value: TaskFilter.area(area)) {
                                HStack {
                                    Image(systemName: area.icon)
                                        .foregroundStyle(Color(area.color))
                                        .frame(width: 28)
                                    
                                    Text(area.name)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if areaTaskCount(for: area) > 0 {
                                        Text("\(areaTaskCount(for: area))")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                            
                            // Inline project creation for this area
                            if isCreatingProject && newProjectAreaId == area.id {
                                InlineProjectCreationView(
                                    projectName: $newProjectName,
                                    selectedAreaId: $newProjectAreaId,
                                    areas: viewModel.areas,
                                    onSave: {
                                        saveNewProject()
                                    },
                                    onCancel: {
                                        cancelProjectCreation()
                                    }
                                )
                            }
                            
                            // Projects in this area
                            ForEach(viewModel.projects.filter { $0.areaId == area.id }) { project in
                                NavigationLink(value: TaskFilter.project(project)) {
                                    ProjectRow(project: project, viewModel: viewModel)
                                }
                            }
                        }
                    }
                }
                
                // Projects without areas
                let orphanProjects = viewModel.projects.filter { $0.areaId == nil }
                if !orphanProjects.isEmpty || isCreatingProject {
                    Section("Projects") {
                        if isCreatingProject && newProjectAreaId == nil {
                            InlineProjectCreationView(
                                projectName: $newProjectName,
                                selectedAreaId: $newProjectAreaId,
                                areas: viewModel.areas,
                                onSave: {
                                    saveNewProject()
                                },
                                onCancel: {
                                    cancelProjectCreation()
                                }
                            )
                        }
                        
                        ForEach(orphanProjects) { project in
                            NavigationLink(value: TaskFilter.project(project)) {
                                ProjectRow(project: project, viewModel: viewModel)
                            }
                        }
                    }
                }
            }
            .id(viewModel.projects.count)
            .listStyle(.insetGrouped)
            .navigationTitle("Tasks")
            .navigationDestination(for: TaskFilter.self) { filter in
                TasksSectionDetailView(viewModel: viewModel, filter: filter)
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView(viewModel: viewModel)
            }
            }
            
            // Floating Action Button
            if !showingQuickAddOverlay {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingActionButton {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                showingQuickAddOverlay = true
                            }
                        }
                        .padding()
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Overlay for quick add menu
            if showingQuickAddOverlay {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingQuickAddOverlay = false
                        }
                    }
                
                VStack {
                    Spacer()
                    
                    QuickAddOverlay(
                        isPresented: $showingQuickAddOverlay,
                        onTaskSelected: {
                            showingAddTask = true
                        },
                        onProjectSelected: {
                            isCreatingProject = true
                            newProjectName = ""
                            newProjectAreaId = nil
                        },
                        onAreaSelected: {
                            // TODO: Show Add Area view
                            print("Add Area selected")
                        }
                    )
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Helper Methods
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
    
    private func areaTaskCount(for area: Area) -> Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.areaId == area.id && $0.projectId == nil }.count
    }
    
    private func saveNewProject() {
        guard !newProjectName.isEmpty else { return }
        
        let newProject = Project(
            name: newProjectName,
            areaId: newProjectAreaId,
            color: "blue",
            icon: "folder"
        )
        
        viewModel.addProject(newProject)
        
        // Reset state after a slight delay to ensure UI updates
        DispatchQueue.main.async {
            self.isCreatingProject = false
            self.newProjectName = ""
            self.newProjectAreaId = nil
        }
    }
    
    private func cancelProjectCreation() {
        isCreatingProject = false
        newProjectName = ""
        newProjectAreaId = nil
    }
}

// MARK: - Task Section Row
struct TaskSectionRow: View {
    let section: TaskSection
    let count: Int
    let viewModel: TasksViewModel
    
    var body: some View {
        HStack {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
                .font(.title3)
                .frame(width: 28)
            
            Text(section.rawValue)
                .font(.body)
            
            Spacer()
            
            if count > 0 {
                Text("\(count)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Area Header View
struct AreaHeaderView: View {
    let area: Area
    
    var body: some View {
        HStack {
            Image(systemName: area.icon)
                .foregroundStyle(Color(area.color))
                .font(.caption)
            
            Text(area.name.uppercased())
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Project Row
struct ProjectRow: View {
    let project: Project
    let viewModel: TasksViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(project.color))
                .frame(width: 8, height: 8)
                .padding(.leading, 20)
            
            Text(project.name)
                .font(.body)
            
            Spacer()
            
            if project.progress > 0 {
                CircularProgressView(progress: project.progress)
                    .frame(width: 20, height: 20)
            }
            
            let taskCount = viewModel.tasks.filter { !$0.isCompleted && $0.projectId == project.id }.count
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
    TasksView(viewModel: TasksViewModel())
}
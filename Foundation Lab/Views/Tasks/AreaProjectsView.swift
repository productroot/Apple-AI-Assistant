//
//  AreaProjectsView.swift
//  Sophia Flow
//
//  Created by Assistant on 1/17/25.
//

import SwiftUI

struct AreaProjectsView: View {
    let area: Area
    let viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddProject = false
    @State private var sortOption: TaskSortOption = .priority
    
    init(area: Area, viewModel: TasksViewModel) {
        self.area = area
        self.viewModel = viewModel
        print("🎯 AreaProjectsView INIT for area: \(area.name)")
    }
    
    private var projectsInArea: [Project] {
        let projects = viewModel.projects.filter { $0.areaId == area.id }
        print("🔍 AreaProjectsView projectsInArea for \(area.name): \(projects.count)")
        return projects
    }
    
    private var directTasksInArea: [TodoTask] {
        let tasks = viewModel.tasks.filter { $0.areaId == area.id && $0.projectId == nil && !$0.isCompleted }
        print("🔍 AreaProjectsView directTasksInArea for \(area.name): \(tasks.count)")
        return tasks
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Direct tasks in area (always show section, even if empty)
                Section {
                    if !directTasksInArea.isEmpty {
                        ForEach(directTasksInArea) { task in
                            NavigationLink(destination: TaskDetailView(task: task, viewModel: viewModel)) {
                                TaskRowView(
                                    task: task,
                                    viewModel: viewModel,
                                    isSelected: false,
                                    onTap: {},
                                    editingTask: nil
                                )
                            }
                        }
                    } else {
                        Text("No direct tasks in this area")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                } header: {
                    HStack {
                        Text("Tasks")
                        Spacer()
                        Text("\(directTasksInArea.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Projects in area (always show section, even if empty)
                Section {
                    if !projectsInArea.isEmpty {
                        ForEach(projectsInArea) { project in
                            NavigationLink(destination: TasksSectionDetailView(viewModel: viewModel, filter: .project(project))) {
                                HStack {
                                    Circle()
                                        .fill(project.displayColor)
                                        .frame(width: 28, height: 28)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(project.name)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                        
                                        if !project.notes.isEmpty {
                                            Text(project.notes)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .lineLimit(2)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        if projectTaskCount(for: project) > 0 {
                                            Text("\(projectTaskCount(for: project))")
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        if project.progress > 0 {
                                            ProgressView(value: project.progress)
                                                .progressViewStyle(LinearProgressViewStyle())
                                                .frame(width: 40)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    } else {
                        Text("No projects in this area")
                            .foregroundStyle(.secondary)
                            .font(.body)
                    }
                } header: {
                    HStack {
                        Text("Projects")
                        Spacer()
                        Text("\(projectsInArea.count)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(area.name)
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                sortOption = viewModel.sortOption
                print("🔍 AreaProjectsView Debug for area: \(area.name)")
                print("   Area ID: \(area.id)")
                print("   Total projects in viewModel: \(viewModel.projects.count)")
                print("   Total tasks in viewModel: \(viewModel.tasks.count)")
                print("   Projects in this area: \(projectsInArea.count)")
                print("   Direct tasks in this area: \(directTasksInArea.count)")
                
                print("   All projects:")
                for project in viewModel.projects {
                    print("     - \(project.name) (areaId: \(project.areaId?.uuidString ?? "nil"))")
                }
                
                print("   All tasks:")
                for task in viewModel.tasks {
                    print("     - \(task.title) (areaId: \(task.areaId?.uuidString ?? "nil"), projectId: \(task.projectId?.uuidString ?? "nil"))")
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Picker("Sort by", selection: $sortOption) {
                            ForEach(TaskSortOption.allCases, id: \.self) { option in
                                Label(option.displayName, systemImage: option.icon)
                                    .tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: sortOption.icon)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Project") {
                        showingAddProject = true
                    }
                }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView(viewModel: viewModel, preselectedArea: area)
            }
            .onChange(of: sortOption) { _, newValue in
                viewModel.sortOption = newValue
            }
        }
    }
    
    private func projectTaskCount(for project: Project) -> Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.projectId == project.id }.count
    }
}

#Preview {
    AreaProjectsView(
        area: Area(name: "Work", icon: "briefcase", color: "blue"),
        viewModel: TasksViewModel.shared
    )
}
import SwiftUI
#if os(iOS)
import UIKit
#endif

struct OrphanProjectsSection: View {
    let viewModel: TasksViewModel
    @Binding var projectToEdit: Project?
    @Binding var projectToDelete: Project?
    @Binding var showingDeleteProjectAlert: Bool
#if os(iOS)
    @Binding var editMode: EditMode
#else
    @Binding var editMode: Bool
#endif
    let showExplainers: Bool
    var onNavigateToProject: ((Project) -> Void)?
    
    var orphanProjects: [Project] {
        viewModel.projects.filter { $0.areaId == nil }
    }
    
    var body: some View {
        if !orphanProjects.isEmpty {
            Section(header: VStack(alignment: .leading, spacing: 2) {
                Text("Projects")
                    .font(.headline)
                if showExplainers {
                    Text("Projects not assigned to any area")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .transition(.asymmetric(
                            insertion: .push(from: .top).combined(with: .opacity),
                            removal: .push(from: .bottom).combined(with: .opacity)
                        ))
                }
            }) {
                ForEach(orphanProjects) { project in
                    NavigationLink(value: TaskFilter.project(project)) {
                        HStack(spacing: 12) {
                            let allProjectTasks = viewModel.tasks.filter { $0.projectId == project.id }
                            let openProjectTasks = allProjectTasks.filter { !$0.isCompleted }
                            let completionProgress = allProjectTasks.isEmpty ? 0.0 : Double(allProjectTasks.count - openProjectTasks.count) / Double(allProjectTasks.count)
                            
                            ZStack {
                                Circle()
                                    .stroke(project.displayColor.opacity(0.3), lineWidth: 1.5)
                                    .frame(width: 16, height: 16)
                                
                                Circle()
                                    .trim(from: 0, to: completionProgress)
                                    .stroke(project.displayColor, lineWidth: 1.5)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.3), value: completionProgress)
                                    .frame(width: 16, height: 16)
                            }
                            
                            Text(project.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if project.progress > 0 {
                                CircularProgressView(progress: project.progress)
                                    .frame(width: 20, height: 20)
                            }
                            
                            let taskCount = openProjectTasks.count
                            if taskCount > 0 {
                                Text("\(taskCount)")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
#if os(iOS)
                    .disabled(editMode == .active)
#else
                    .disabled(editMode)
#endif
                    .listRowInsets(EdgeInsets())
#if os(iOS)
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
#else
                    .listRowBackground(Color(NSColor.controlBackgroundColor))
#endif
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
#if os(iOS)
                        if editMode == .inactive {
                            Button(role: .destructive) {
                                projectToDelete = project
                                showingDeleteProjectAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                projectToEdit = project
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
#else
                        if !editMode {
                            Button(role: .destructive) {
                                projectToDelete = project
                                showingDeleteProjectAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                projectToEdit = project
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
#endif
                    }
                }
                .onMove { from, to in
                    moveOrphanProjects(from: from, to: to)
                }
                .onDelete { indices in
                    deleteOrphanProjects(at: indices)
                }
            }
        }
    }
    
    private func moveOrphanProjects(from source: IndexSet, to destination: Int) {
        var reorderedProjects = orphanProjects
        reorderedProjects.move(fromOffsets: source, toOffset: destination)
        
        // Update the order in the main projects array
        for (_, project) in reorderedProjects.enumerated() {
            if let globalIndex = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                viewModel.projects[globalIndex] = project
            }
        }
        
        viewModel.saveToiCloudIfEnabled()
    }
    
    private func deleteOrphanProjects(at offsets: IndexSet) {
        for index in offsets {
            if index < orphanProjects.count {
                projectToDelete = orphanProjects[index]
                showingDeleteProjectAlert = true
            }
        }
    }
}
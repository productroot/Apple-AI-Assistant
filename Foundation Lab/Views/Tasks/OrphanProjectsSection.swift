import SwiftUI

struct OrphanProjectsSection: View {
    let viewModel: TasksViewModel
    @Binding var projectToEdit: Project?
    @Binding var projectToDelete: Project?
    @Binding var showingDeleteProjectAlert: Bool
    @Binding var editMode: EditMode
    var onNavigateToProject: ((Project) -> Void)?
    
    var orphanProjects: [Project] {
        viewModel.projects.filter { $0.areaId == nil }
    }
    
    var body: some View {
        if !orphanProjects.isEmpty {
            Section("Projects") {
                ForEach(orphanProjects) { project in
                    Button(action: {
                        if editMode == .inactive {
                            onNavigateToProject?(project)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(project.color))
                                .frame(width: 8, height: 8)
                            
                            Text(project.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            
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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color(UIColor.secondarySystemGroupedBackground))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
        for (index, project) in reorderedProjects.enumerated() {
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
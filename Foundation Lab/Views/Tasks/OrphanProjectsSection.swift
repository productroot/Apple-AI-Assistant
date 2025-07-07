import SwiftUI

struct OrphanProjectsSection: View {
    let viewModel: TasksViewModel
    @Binding var projectToEdit: Project?
    @Binding var projectToDelete: Project?
    @Binding var showingDeleteProjectAlert: Bool
    
    var orphanProjects: [Project] {
        viewModel.projects.filter { $0.areaId == nil }
    }
    
    var body: some View {
        if !orphanProjects.isEmpty {
            Section("Projects") {
                ForEach(orphanProjects) { project in
                    ProjectRowView(
                        project: project,
                        viewModel: viewModel,
                        projectToEdit: $projectToEdit,
                        projectToDelete: $projectToDelete,
                        showingDeleteProjectAlert: $showingDeleteProjectAlert
                    )
                }
                .onMove { source, destination in
                    moveOrphanProjects(from: source, to: destination)
                }
            }
        }
    }
    
    private func moveOrphanProjects(from source: IndexSet, to destination: Int) {
        var orphanProjectsList = orphanProjects
        orphanProjectsList.move(fromOffsets: source, toOffset: destination)
        
        let areaProjects = viewModel.projects.filter { $0.areaId != nil }
        viewModel.projects = areaProjects + orphanProjectsList
        
        if let firstProject = viewModel.projects.first {
            viewModel.updateProject(firstProject)
        }
    }
}
import SwiftUI

struct ProjectRowView: View {
    let project: Project
    let viewModel: TasksViewModel
    @Binding var projectToEdit: Project?
    @Binding var projectToDelete: Project?
    @Binding var showingDeleteProjectAlert: Bool
    
    var body: some View {
        NavigationLink(value: TaskFilter.project(project)) {
            ProjectRow(project: project, viewModel: viewModel)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
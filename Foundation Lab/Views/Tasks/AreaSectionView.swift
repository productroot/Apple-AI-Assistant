import SwiftUI

struct AreaSectionView: View {
    let area: Area
    let viewModel: TasksViewModel
    @Binding var isCreatingProject: Bool
    @Binding var newProjectName: String
    @Binding var newProjectAreaId: UUID?
    @Binding var areaToEdit: Area?
    @Binding var areaToDelete: Area?
    @Binding var showingDeleteAreaAlert: Bool
    @Binding var projectToEdit: Project?
    @Binding var projectToDelete: Project?
    @Binding var showingDeleteProjectAlert: Bool
    let onSaveProject: () -> Void
    let onCancelProject: () -> Void
    
    var body: some View {
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
                    
                    if areaTaskCount > 0 {
                        Text("\(areaTaskCount)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    areaToDelete = area
                    showingDeleteAreaAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                Button {
                    areaToEdit = area
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
            .contextMenu {
                Button {
                    areaToEdit = area
                } label: {
                    Label("Edit Area", systemImage: "pencil")
                }
                
                Button {
                    isCreatingProject = true
                    newProjectName = ""
                    newProjectAreaId = area.id
                } label: {
                    Label("Add Project", systemImage: "plus.circle")
                }
                
                Divider()
                
                Button(role: .destructive) {
                    areaToDelete = area
                    showingDeleteAreaAlert = true
                } label: {
                    Label("Delete Area", systemImage: "trash")
                }
            }
            
            // Inline project creation for this area
            if isCreatingProject && newProjectAreaId == area.id {
                InlineProjectCreationView(
                    projectName: $newProjectName,
                    selectedAreaId: $newProjectAreaId,
                    areas: viewModel.areas,
                    onSave: onSaveProject,
                    onCancel: onCancelProject
                )
            }
            
            // Projects in this area
            ForEach(viewModel.projects.filter { $0.areaId == area.id }) { project in
                ProjectRowView(
                    project: project,
                    viewModel: viewModel,
                    projectToEdit: $projectToEdit,
                    projectToDelete: $projectToDelete,
                    showingDeleteProjectAlert: $showingDeleteProjectAlert
                )
            }
            .onMove { source, destination in
                moveProjects(in: area, from: source, to: destination)
            }
        }
    }
    
    private var areaTaskCount: Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.areaId == area.id }.count
    }
    
    private func moveProjects(in area: Area, from source: IndexSet, to destination: Int) {
        var areaProjects = viewModel.projects.filter { $0.areaId == area.id }
        areaProjects.move(fromOffsets: source, toOffset: destination)
        
        let otherProjects = viewModel.projects.filter { $0.areaId != area.id }
        viewModel.projects = otherProjects + areaProjects
        
        if let firstProject = viewModel.projects.first {
            viewModel.updateProject(firstProject)
        }
    }
}
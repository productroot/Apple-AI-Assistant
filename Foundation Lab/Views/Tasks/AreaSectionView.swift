import SwiftUI
#if os(iOS)
import UIKit
#endif

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
#if os(iOS)
    @Binding var editMode: EditMode
#else
    @Binding var editMode: Bool
#endif
    let onSaveProject: () -> Void
    let onCancelProject: () -> Void
    var onNavigateToProject: ((Project) -> Void)?
    
    var body: some View {
        Section {
            // Area header
            HStack {
                NavigationLink(value: TaskFilter.area(area)) {
                    HStack {
                        Image(systemName: area.icon)
                            .foregroundStyle(area.displayColor)
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
                }
                .buttonStyle(.plain)
                
                Button {
                    isCreatingProject = true
                    newProjectName = ""
                    newProjectAreaId = area.id
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
#if os(iOS)
                if editMode == .inactive {
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
#else
                if !editMode {
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
#endif
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
                        .padding(.leading, 20)
                        
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
                moveProjects(in: area, from: from, to: to)
            }
            .onDelete { indices in
                deleteProjects(in: area, at: indices)
            }
        }
    }
    
    private var areaTaskCount: Int {
        viewModel.tasks.filter { !$0.isCompleted && $0.areaId == area.id }.count
    }
    
    private func moveProjects(in area: Area, from source: IndexSet, to destination: Int) {
        let areaProjects = viewModel.projects.filter { $0.areaId == area.id }
        var reorderedProjects = areaProjects
        reorderedProjects.move(fromOffsets: source, toOffset: destination)
        
        // Update the order in the main projects array
        for (_, project) in reorderedProjects.enumerated() {
            if let globalIndex = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                viewModel.projects[globalIndex] = project
            }
        }
        
        viewModel.saveToiCloudIfEnabled()
    }
    
    private func deleteProjects(in area: Area, at offsets: IndexSet) {
        let areaProjects = viewModel.projects.filter { $0.areaId == area.id }
        for index in offsets {
            if index < areaProjects.count {
                projectToDelete = areaProjects[index]
                showingDeleteProjectAlert = true
            }
        }
    }
}
import SwiftUI

struct TaskMoveView: View {
    let task: TodoTask
    let viewModel: TasksViewModel
    let onDismiss: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Projects") {
                    ForEach(viewModel.projects) { project in
                        Button {
                            moveToProject(project)
                        } label: {
                            HStack {
                                Circle()
                                    .fill(project.displayColor)
                                    .frame(width: 10, height: 10)
                                
                                Text(project.name)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if task.projectId == project.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
                
                Section("Areas") {
                    ForEach(viewModel.areas) { area in
                        Button {
                            moveToArea(area)
                        } label: {
                            HStack {
                                Image(systemName: area.icon)
                                    .foregroundStyle(area.displayColor)
                                
                                Text(area.name)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if task.areaId == area.id && task.projectId == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }
    
    private func moveToProject(_ project: Project) {
        var updatedTask = task
        updatedTask.projectId = project.id
        updatedTask.areaId = project.areaId
        
        viewModel.updateTask(updatedTask)
        dismiss()
        onDismiss()
    }
    
    private func moveToArea(_ area: Area) {
        var updatedTask = task
        updatedTask.areaId = area.id
        updatedTask.projectId = nil
        
        viewModel.updateTask(updatedTask)
        dismiss()
        onDismiss()
    }
} 
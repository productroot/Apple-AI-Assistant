import SwiftUI

struct ProjectHeaderView: View {
    let project: Project
    let viewModel: TasksViewModel
    let taskCount: Int
    
    @State private var isEditingName = false
    @State private var editedName = ""
    @State private var showingDeadlineSheet = false
    @State private var showingMoveSheet = false
    @FocusState private var isNameFieldFocused: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color(project.color))
                .frame(width: 10, height: 10)
            
            if isEditingName {
                TextField("Project name", text: $editedName)
                    .font(.headline)
                    .fontWeight(.medium)
                    .textFieldStyle(.plain)
                    .focused($isNameFieldFocused)
                    .onSubmit {
                        saveProjectName()
                    }
                    .onAppear {
                        editedName = project.name
                        isNameFieldFocused = true
                    }
            } else {
                Text(project.name)
                    .font(.headline)
                    .fontWeight(.medium)
                    .onTapGesture {
                        startEditingName()
                    }
            }
            
            Spacer()
            
            if taskCount > 0 {
                Text("\(taskCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5))
                    .cornerRadius(4)
            }
            
            Menu {
                Section {
                    Button {
                        // TODO: Implement When functionality
                    } label: {
                        Label("When", systemImage: "calendar")
                    }
                    
                    Button {
                        showingDeadlineSheet = true
                    } label: {
                        Label("Set Deadline", systemImage: "flag")
                    }
                    
                    Button {
                        showingMoveSheet = true
                    } label: {
                        Label("Move", systemImage: "arrow.right")
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .menuStyle(.button)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditingName && !isNameFieldFocused {
                saveProjectName()
            }
        }
        .sheet(isPresented: $showingDeadlineSheet) {
            ProjectDeadlineSheet(project: project, viewModel: viewModel)
        }
        .sheet(isPresented: $showingMoveSheet) {
            ProjectMoveSheet(project: project, viewModel: viewModel)
        }
    }
    
    private func startEditingName() {
        editedName = project.name
        isEditingName = true
    }
    
    private func saveProjectName() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty && trimmedName != project.name {
            var updatedProject = project
            updatedProject.name = trimmedName
            viewModel.updateProject(updatedProject)
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            isEditingName = false
        }
        isNameFieldFocused = false
    }
}

// MARK: - Project Deadline Sheet
struct ProjectDeadlineSheet: View {
    let project: Project
    let viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate = Date()
    @State private var hasDeadline: Bool
    
    init(project: Project, viewModel: TasksViewModel) {
        self.project = project
        self.viewModel = viewModel
        _hasDeadline = State(initialValue: project.deadline != nil)
        _selectedDate = State(initialValue: project.deadline ?? Date())
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Toggle("Set Deadline", isOn: $hasDeadline)
                
                if hasDeadline {
                    DatePicker("Deadline", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
            }
            .navigationTitle("Project Deadline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        var updatedProject = project
                        updatedProject.deadline = hasDeadline ? selectedDate : nil
                        viewModel.updateProject(updatedProject)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Project Move Sheet
struct ProjectMoveSheet: View {
    let project: Project
    let viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAreaId: UUID?
    
    init(project: Project, viewModel: TasksViewModel) {
        self.project = project
        self.viewModel = viewModel
        _selectedAreaId = State(initialValue: project.areaId)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Move to Area") {
                    Button {
                        selectedAreaId = nil
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundStyle(.secondary)
                                .frame(width: 28)
                            
                            Text("No Area")
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedAreaId == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    
                    ForEach(viewModel.areas) { area in
                        Button {
                            selectedAreaId = area.id
                        } label: {
                            HStack {
                                Image(systemName: area.icon)
                                    .foregroundStyle(Color(area.color))
                                    .frame(width: 28)
                                
                                Text(area.name)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if selectedAreaId == area.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Move Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Move") {
                        var updatedProject = project
                        updatedProject.areaId = selectedAreaId
                        viewModel.updateProject(updatedProject)
                        
                        // Move all tasks in this project to the new area
                        let tasksToUpdate = viewModel.tasks.filter { $0.projectId == project.id }
                        for task in tasksToUpdate {
                            var updatedTask = task
                            updatedTask.areaId = selectedAreaId
                            viewModel.updateTask(updatedTask)
                        }
                        
                        dismiss()
                    }
                }
            }
        }
    }
} 
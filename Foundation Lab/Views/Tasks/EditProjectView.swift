import SwiftUI

struct EditProjectView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TasksViewModel
    let project: Project
    
    @State private var name: String
    @State private var notes: String
    @State private var selectedAreaId: UUID?
    @State private var deadline: Date?
    @State private var hasDeadline: Bool
    @State private var selectedColor: String
    @State private var selectedIcon: String
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink",
        "yellow", "teal", "indigo", "brown", "gray"
    ]
    
    private let availableIcons = [
        "folder", "star", "flag", "bookmark", "paperclip",
        "doc", "book", "tray", "archivebox", "folder.fill"
    ]
    
    init(viewModel: TasksViewModel, project: Project) {
        self.viewModel = viewModel
        self.project = project
        _name = State(initialValue: project.name)
        _notes = State(initialValue: project.notes)
        _selectedAreaId = State(initialValue: project.areaId)
        _deadline = State(initialValue: project.deadline)
        _hasDeadline = State(initialValue: project.deadline != nil)
        _selectedColor = State(initialValue: project.color)
        _selectedIcon = State(initialValue: project.icon)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Project Details") {
                    TextField("Name", text: $name)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Organization") {
                    Picker("Area", selection: $selectedAreaId) {
                        Text("No Area").tag(nil as UUID?)
                        ForEach(viewModel.areas) { area in
                            Label(area.name, systemImage: area.icon)
                                .tag(area.id as UUID?)
                        }
                    }
                }
                
                Section("Deadline") {
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? Date() },
                            set: { deadline = $0 }
                        ), displayedComponents: [.date])
                    }
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                            ForEach(availableIcons, id: \.self) { icon in
                                Button {
                                    selectedIcon = icon
                                } label: {
                                    Image(systemName: icon)
                                        .font(.title3)
                                        .frame(width: 50, height: 50)
                                        .background(selectedIcon == icon ? Color.accentColor.opacity(0.2) : Color.clear)
                                        .cornerRadius(10)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                            ForEach(availableColors, id: \.self) { color in
                                Button {
                                    selectedColor = color
                                } label: {
                                    Circle()
                                        .fill(Color(color))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle()
                                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 3)
                                        )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Edit Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        var updatedProject = project
        updatedProject.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedProject.notes = notes
        updatedProject.areaId = selectedAreaId
        updatedProject.deadline = hasDeadline ? deadline : nil
        updatedProject.color = selectedColor
        updatedProject.icon = selectedIcon
        
        viewModel.updateProject(updatedProject)
        dismiss()
    }
}

#Preview {
    EditProjectView(
        viewModel: TasksViewModel(),
        project: Project(name: "Sample Project", color: "blue", icon: "folder")
    )
}
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
        // Primary Colors
        "red", "orange", "yellow", "green", "blue", "purple",
        
        // Extended Colors
        "pink", "teal", "indigo", "mint", "cyan", "brown",
        
        // Additional System Colors
        "gray", "black", "white",
        
        // Custom Named Colors (will use system adaptations)
        "systemRed", "systemOrange", "systemYellow", "systemGreen",
        "systemTeal", "systemBlue", "systemIndigo", "systemPurple",
        "systemPink", "systemBrown", "systemGray", "systemGray2",
        "systemGray3", "systemGray4", "systemGray5", "systemGray6"
    ]
    
    private let availableIcons = [
        // Organization
        "folder", "folder.fill", "folder.circle", "folder.badge.plus",
        "archivebox", "archivebox.fill", "tray", "tray.fill",
        
        // Work & Business
        "briefcase", "briefcase.fill", "building.2", "building.2.fill",
        "chart.line.uptrend.xyaxis", "chart.bar", "dollarsign.circle", "creditcard",
        
        // Creative & Design
        "paintbrush", "paintbrush.fill", "paintpalette", "paintpalette.fill",
        "camera", "camera.fill", "photo", "photo.fill",
        
        // Development & Tech
        "hammer", "hammer.fill", "wrench.and.screwdriver", "wrench.and.screwdriver.fill",
        "cpu", "desktopcomputer", "laptopcomputer", "iphone",
        
        // Education & Learning
        "book", "book.fill", "graduationcap", "graduationcap.fill",
        "pencil", "pencil.circle", "doc.text", "doc.text.fill",
        
        // Health & Fitness
        "heart", "heart.fill", "figure.walk", "figure.run",
        "dumbbell", "dumbbell.fill", "cross.case", "cross.case.fill",
        
        // Travel & Places
        "airplane", "car", "car.fill", "tram",
        "house", "house.fill", "building", "building.fill",
        
        // Nature & Environment
        "leaf", "leaf.fill", "tree", "tree.fill",
        "sun.max", "sun.max.fill", "moon", "moon.fill",
        
        // Communication
        "envelope", "envelope.fill", "phone", "phone.fill",
        "message", "message.fill", "bubble.left.and.bubble.right", "video",
        
        // General Purpose
        "star", "star.fill", "flag", "flag.fill",
        "bookmark", "bookmark.fill", "tag", "tag.fill",
        "bell", "bell.fill", "lightbulb", "lightbulb.fill",
        "gear", "gearshape", "puzzlepiece", "puzzlepiece.fill"
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
                        .datePickerStyle(.graphical)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        
                        Button("Remove Deadline") {
                            hasDeadline = false
                            deadline = nil
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("Appearance") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 6), spacing: 8) {
                                ForEach(availableIcons, id: \.self) { icon in
                                    Button {
                                        selectedIcon = icon
                                    } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .frame(width: 44, height: 44)
                                            .foregroundColor(selectedIcon == icon ? .white : .primary)
                                            .background(selectedIcon == icon ? Color.accentColor : Color.secondary.opacity(0.1))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedIcon == icon ? Color.accentColor : Color.clear, lineWidth: 2)
                                            )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 300)
                    }
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ScrollView {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8), spacing: 8) {
                                ForEach(availableColors, id: \.self) { colorName in
                                    Button {
                                        selectedColor = colorName
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(getColor(for: colorName))
                                                .frame(width: 36, height: 36)
                                            
                                            if selectedColor == colorName {
                                                Circle()
                                                    .stroke(Color.primary, lineWidth: 3)
                                                    .frame(width: 36, height: 36)
                                                
                                                Image(systemName: "checkmark")
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(colorName == "white" || colorName == "yellow" ? .black : .white)
                                            }
                                        }
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: 200)
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
    
    private func getColor(for colorName: String) -> Color {
        Color.projectColor(named: colorName)
    }
}

#Preview {
    EditProjectView(
        viewModel: TasksViewModel(),
        project: Project(name: "Sample Project", color: "blue", icon: "folder")
    )
}
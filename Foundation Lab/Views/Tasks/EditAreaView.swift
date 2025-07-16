import SwiftUI

struct EditAreaView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TasksViewModel
    let area: Area
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
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
    
    init(viewModel: TasksViewModel, area: Area) {
        self.viewModel = viewModel
        self.area = area
        _name = State(initialValue: area.name)
        _selectedIcon = State(initialValue: area.icon)
        _selectedColor = State(initialValue: area.color)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Area Details") {
                    TextField("Name", text: $name)
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
            .navigationTitle("Edit Area")
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
        var updatedArea = area
        updatedArea.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedArea.icon = selectedIcon
        updatedArea.color = selectedColor
        
        viewModel.updateArea(updatedArea)
        dismiss()
    }
    
    private func getColor(for colorName: String) -> Color {
        Color.projectColor(named: colorName)
    }
}

#Preview {
    EditAreaView(
        viewModel: TasksViewModel.shared,
        area: Area(name: "Work", icon: "briefcase", color: "blue")
    )
}
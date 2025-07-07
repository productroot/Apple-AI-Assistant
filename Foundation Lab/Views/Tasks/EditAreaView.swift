import SwiftUI

struct EditAreaView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: TasksViewModel
    let area: Area
    
    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: String
    
    private let availableIcons = [
        "square.stack.3d.up", "folder", "house", "briefcase", "heart",
        "star", "flag", "tag", "book", "cart", "airplane", "car"
    ]
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink",
        "yellow", "teal", "indigo", "brown", "gray"
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
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6)) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
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
                    .padding(.vertical, 8)
                }
                
                Section("Color") {
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
                    .padding(.vertical, 8)
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
}

#Preview {
    EditAreaView(
        viewModel: TasksViewModel(),
        area: Area(name: "Work", icon: "briefcase", color: "blue")
    )
}
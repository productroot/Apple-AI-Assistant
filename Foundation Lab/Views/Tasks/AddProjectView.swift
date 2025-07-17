//
//  AddProjectView.swift
//  Sophia Flow
//
//  Created by Assistant on 1/17/25.
//

import SwiftUI

struct AddProjectView: View {
    var viewModel: TasksViewModel
    var preselectedArea: Area? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var notes = ""
    @State private var selectedArea: Area?
    @State private var deadline: Date?
    @State private var hasDeadline = false
    @State private var selectedColor = "blue"
    @State private var selectedIcon = "folder"
    
    private let availableColors = ["blue", "green", "red", "orange", "purple", "pink", "yellow", "cyan", "indigo", "mint"]
    private let availableIcons = ["folder", "briefcase", "house", "heart", "star", "bookmark", "gamecontroller", "book", "music.note", "camera"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Project Name", text: $name)
                        .font(.headline)
                    
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    // Area Selection
                    if !viewModel.areas.isEmpty {
                        Picker("Area", selection: $selectedArea) {
                            Text("None").tag(nil as Area?)
                            ForEach(viewModel.areas) { area in
                                Label(area.name, systemImage: area.icon)
                                    .tag(area as Area?)
                            }
                        }
                    }
                    
                    // Deadline
                    Toggle("Set Deadline", isOn: $hasDeadline)
                    
                    if hasDeadline {
                        DatePicker("Deadline", selection: Binding(
                            get: { deadline ?? Date() },
                            set: { deadline = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                Section("Appearance") {
                    // Color Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableColors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color.projectColor(named: color))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Icon Selection
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(availableIcons, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .foregroundStyle(Color.projectColor(named: selectedColor))
                                    .font(.title2)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        Circle()
                                            .fill(Color(.systemGray6))
                                            .opacity(selectedIcon == icon ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addProject()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let preselectedArea {
                    selectedArea = preselectedArea
                }
            }
        }
    }
    
    private func addProject() {
        let project = Project(
            name: name,
            notes: notes,
            deadline: hasDeadline ? deadline : nil,
            areaId: selectedArea?.id,
            color: selectedColor,
            icon: selectedIcon
        )
        
        print("📋 Creating project:")
        print("   Name: \(project.name)")
        print("   Area: \(selectedArea?.name ?? "none")")
        print("   Color: \(selectedColor)")
        print("   Icon: \(selectedIcon)")
        
        viewModel.addProject(project)
        dismiss()
    }
}

#Preview {
    AddProjectView(viewModel: TasksViewModel.shared)
}
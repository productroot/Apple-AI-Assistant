//
//  AddTaskView.swift
//  FoundationLab
//
//  Created by Assistant on 7/6/25.
//

import SwiftUI
import Contacts

struct AddTaskView: View {
    var viewModel: TasksViewModel
    var preselectedProject: Project? = nil
    var preselectedArea: Area? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var notes = ""
    @State private var priority: TodoTask.Priority = .none
    @State private var scheduledDate: Date?
    @State private var dueDate: Date?
    @State private var selectedProject: Project?
    @State private var selectedArea: Area?
    @State private var tags: String = ""
    @State private var showDatePicker = false
    @State private var mentionedContacts: [CNContact] = []
    @State private var reminderTime: Date?
    @State private var showIntegratedDatePicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MentionableTextField(
                        text: $title,
                        mentionedContacts: $mentionedContacts,
                        placeholder: "New TodoTask"
                    )
                    .font(.headline)
                    
                    MentionableTextEditor(
                        text: $notes,
                        mentionedContacts: $mentionedContacts,
                        placeholder: "Notes"
                    )
                    .frame(minHeight: 80, maxHeight: 200)
                }
                
                Section {
                    // Priority Picker
                    Picker("Priority", selection: $priority) {
                        ForEach(TodoTask.Priority.allCases, id: \.self) { priority in
                            Label(priority.name, systemImage: priority.icon)
                                .foregroundStyle(priority.color)
                                .tag(priority)
                        }
                    }
                    
                    // Integrated Date & Reminder
                    Button {
                        showIntegratedDatePicker = true
                    } label: {
                        HStack {
                            Label("When", systemImage: "calendar")
                            Spacer()
                            DateReminderMenuLabel(
                                scheduledDate: scheduledDate,
                                reminderTime: reminderTime
                            )
                        }
                    }
                    .foregroundStyle(.primary)
                    
                    // Due Date
                    if let scheduledDate {
                        DatePicker("Deadline", selection: Binding(
                            get: { dueDate ?? scheduledDate },
                            set: { dueDate = $0 }
                        ), in: scheduledDate..., displayedComponents: .date)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                    }
                }
                
                Section {
                    // Area/Project Picker - Mutually exclusive
                    VStack(alignment: .leading, spacing: 8) {
                        if !viewModel.areas.isEmpty || !viewModel.projects.isEmpty {
                            Menu {
                                // Clear selection
                                Button("None") {
                                    selectedArea = nil
                                    selectedProject = nil
                                }
                                
                                // Areas section
                                if !viewModel.areas.isEmpty {
                                    Section("Areas") {
                                        ForEach(viewModel.areas) { area in
                                            Button {
                                                selectedArea = area
                                                selectedProject = nil // Clear project when area is selected
                                            } label: {
                                                Label(area.name, systemImage: area.icon)
                                                    .foregroundStyle(area.displayColor)
                                            }
                                        }
                                    }
                                }
                                
                                // Projects section
                                if !viewModel.projects.isEmpty {
                                    Section("Projects") {
                                        ForEach(viewModel.projects) { project in
                                            Button {
                                                selectedProject = project
                                                selectedArea = viewModel.areas.first { $0.id == project.areaId } // Set area to project's area
                                            } label: {
                                                HStack {
                                                    Circle()
                                                        .fill(project.displayColor)
                                                        .frame(width: 8, height: 8)
                                                    Text(project.name)
                                                }
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text("Location")
                                    Spacer()
                                    if let project = selectedProject {
                                        HStack {
                                            Circle()
                                                .fill(project.displayColor)
                                                .frame(width: 8, height: 8)
                                            Text(project.name)
                                        }
                                        .foregroundStyle(.primary)
                                    } else if let area = selectedArea {
                                        HStack {
                                            Image(systemName: area.icon)
                                                .foregroundStyle(area.displayColor)
                                            Text(area.name)
                                        }
                                        .foregroundStyle(.primary)
                                    } else {
                                        Text("Choose...")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Tags
                    TextField("Tags (comma separated)", text: $tags)
                        .textInputAutocapitalization(.never)
                }
                
                // Mentioned Contacts Section
                if !mentionedContacts.isEmpty {
                    Section("Mentioned Contacts") {
                        ForEach(mentionedContacts, id: \.identifier) { contact in
                            HStack {
                                InteractiveContactView(contact: contact, style: .mention)
                                Spacer()
                                Button {
                                    mentionedContacts.removeAll { $0.identifier == contact.identifier }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New TodoTask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTodoTask()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showIntegratedDatePicker) {
                IntegratedDateReminderPicker(
                    scheduledDate: $scheduledDate,
                    reminderTime: $reminderTime
                )
                .presentationDetents([.large])
            }
            .onAppear {
                if let preselectedProject {
                    selectedProject = preselectedProject
                    print("📋 Pre-selected project: \(preselectedProject.name)")
                }
                if let preselectedArea {
                    selectedArea = preselectedArea
                    print("📋 Pre-selected area: \(preselectedArea.name)")
                }
            }
        }
    }
    
    private func addTodoTask() {
        let tagArray = tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
        
        let task = TodoTask(
            title: title,
            notes: notes,
            tags: tagArray,
            dueDate: dueDate,
            scheduledDate: scheduledDate,
            projectId: selectedProject?.id,
            areaId: selectedArea?.id,
            priority: priority,
            mentionedContactIds: mentionedContacts.map { $0.identifier },
            reminderTime: reminderTime
        )
        
        print("📝 Creating task with location:")
        print("   Project: \(selectedProject?.name ?? "none")")
        print("   Area: \(selectedArea?.name ?? "none")")
        print("   ProjectId: \(selectedProject?.id.uuidString ?? "none")")
        print("   AreaId: \(selectedArea?.id.uuidString ?? "none")")
        
        viewModel.addTask(task)
        print("✅ Added task with \(mentionedContacts.count) mentioned contacts")
        dismiss()
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Binding var selectedDate: Date?
    @Environment(\.dismiss) private var dismiss
    @State private var tempDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick options
                List {
                    Button {
                        selectedDate = Date()
                        dismiss()
                    } label: {
                        Label("Today", systemImage: "star")
                            .foregroundStyle(.yellow)
                    }
                    
                    Button {
                        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
                        dismiss()
                    } label: {
                        Label("Tomorrow", systemImage: "sun.max")
                            .foregroundStyle(.orange)
                    }
                    
                    Button {
                        selectedDate = nextWeekend()
                        dismiss()
                    } label: {
                        Label("This Weekend", systemImage: "beach.umbrella")
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        selectedDate = nil
                        dismiss()
                    } label: {
                        Label("Someday", systemImage: "archivebox")
                            .foregroundStyle(.gray)
                    }
                }
                .listStyle(.insetGrouped)
                
                DatePicker("Select Date", selection: $tempDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .background(Color(.systemBackground))
                    .cornerRadius(8)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("When")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectedDate = tempDate
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func nextWeekend() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        let daysUntilSaturday = (7 - weekday + 7) % 7
        return calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today) ?? today
    }
}
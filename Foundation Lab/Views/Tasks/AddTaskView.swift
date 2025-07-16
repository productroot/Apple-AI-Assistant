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
                    // Area Picker
                    if !viewModel.areas.isEmpty {
                        Picker("Area", selection: $selectedArea) {
                            Text("None").tag(nil as Area?)
                            ForEach(viewModel.areas) { area in
                                Label(area.name, systemImage: area.icon)
                                    .tag(area as Area?)
                            }
                        }
                    }
                    
                    // Project Picker
                    if !viewModel.projects.isEmpty {
                        Picker("Project", selection: $selectedProject) {
                            Text("None").tag(nil as Project?)
                            ForEach(viewModel.projects) { project in
                                HStack {
                                    Circle()
                                        .fill(project.displayColor)
                                        .frame(width: 8, height: 8)
                                    Text(project.name)
                                }
                                .tag(project as Project?)
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
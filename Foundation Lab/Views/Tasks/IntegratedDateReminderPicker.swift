//
//  IntegratedDateReminderPicker.swift
//  Foundation Lab
//
//  Created by Assistant on 7/14/25.
//

import SwiftUI

struct IntegratedDateReminderPicker: View {
    @Binding var scheduledDate: Date?
    @Binding var reminderTime: Date?
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedDate = Date()
    @State private var includeTime = false
    @State private var selectedTime = Date()
    @State private var showingDatePicker = false
    
    init(scheduledDate: Binding<Date?>, reminderTime: Binding<Date?>) {
        self._scheduledDate = scheduledDate
        self._reminderTime = reminderTime
        
        // Initialize state from existing values
        if let date = scheduledDate.wrappedValue {
            _selectedDate = State(initialValue: date)
            
            if let time = reminderTime.wrappedValue {
                _includeTime = State(initialValue: true)
                _selectedTime = State(initialValue: time)
            } else {
                // Default to 9 AM
                let calendar = Calendar.current
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = 9
                components.minute = 0
                _selectedTime = State(initialValue: calendar.date(from: components) ?? Date())
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Quick Options
                List {
                    // Today options
                    Section {
                        Button {
                            setToday()
                            dismiss()
                        } label: {
                            Label("Today", systemImage: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        
                        Button {
                            setTodayEvening()
                            dismiss()
                        } label: {
                            Label("This Evening", systemImage: "moon.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Tomorrow option
                    Section {
                        Button {
                            setTomorrow()
                            dismiss()
                        } label: {
                            Label("Tomorrow", systemImage: "sun.max.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    
                    // Future options
                    Section {
                        Button {
                            setThisWeekend()
                            dismiss()
                        } label: {
                            Label("This Weekend", systemImage: "beach.umbrella.fill")
                                .foregroundStyle(.green)
                        }
                        
                        Button {
                            setNextWeek()
                            dismiss()
                        } label: {
                            Label("Next Week", systemImage: "calendar")
                                .foregroundStyle(.purple)
                        }
                    }
                    
                    // No date option
                    Section {
                        Button {
                            scheduledDate = nil
                            reminderTime = nil
                            dismiss()
                        } label: {
                            Label("Someday", systemImage: "archivebox")
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Custom date section
                    Section {
                        // Date row
                        HStack {
                            Label("Date", systemImage: "calendar")
                            Spacer()
                            Button {
                                showingDatePicker.toggle()
                            } label: {
                                Text(selectedDate, style: .date)
                                    .foregroundStyle(.blue)
                            }
                        }
                        
                        // Time toggle row
                        Toggle(isOn: $includeTime) {
                            Label("Time", systemImage: "clock")
                        }
                        .onChange(of: includeTime) { _, enabled in
                            if enabled {
                                // Set default time to 9 AM when enabled
                                let calendar = Calendar.current
                                var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                                components.hour = 9
                                components.minute = 0
                                selectedTime = calendar.date(from: components) ?? Date()
                            }
                        }
                        
                        // Time picker row (shown when time is enabled)
                        if includeTime {
                            DatePicker(
                                "",
                                selection: $selectedTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .frame(height: 150)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("When?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        applySelection()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    DatePicker(
                        "Select Date",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .navigationTitle("Select Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Quick Date Helpers
    
    private func setToday() {
        let now = Date()
        scheduledDate = Calendar.current.startOfDay(for: now)
        
        // Set reminder for 9 AM today
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 9
        components.minute = 0
        
        if let nineAM = calendar.date(from: components), nineAM > now {
            // If it's before 9 AM, set reminder for 9 AM
            reminderTime = nineAM
        } else {
            // If it's after 9 AM, set reminder for 1 hour from now
            reminderTime = calendar.date(byAdding: .hour, value: 1, to: now)
        }
    }
    
    private func setTodayEvening() {
        let calendar = Calendar.current
        let now = Date()
        
        scheduledDate = calendar.startOfDay(for: now)
        
        // Set reminder for 6 PM today
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 18
        components.minute = 0
        reminderTime = calendar.date(from: components)
    }
    
    private func setTomorrow() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!
        
        scheduledDate = calendar.startOfDay(for: tomorrow)
        
        // Set reminder for 9 AM tomorrow
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        components.hour = 9
        components.minute = 0
        reminderTime = calendar.date(from: components)
    }
    
    private func setThisWeekend() {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        
        // Calculate days until Saturday
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let saturday = calendar.date(byAdding: .day, value: daysUntilSaturday == 0 ? 7 : daysUntilSaturday, to: today)!
        
        scheduledDate = calendar.startOfDay(for: saturday)
        
        // Set reminder for 10 AM on Saturday
        var components = calendar.dateComponents([.year, .month, .day], from: saturday)
        components.hour = 10
        components.minute = 0
        reminderTime = calendar.date(from: components)
    }
    
    private func setNextWeek() {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())!
        let monday = calendar.dateInterval(of: .weekOfYear, for: nextWeek)?.start ?? nextWeek
        
        scheduledDate = calendar.startOfDay(for: monday)
        
        // Set reminder for 9 AM Monday
        var components = calendar.dateComponents([.year, .month, .day], from: monday)
        components.hour = 9
        components.minute = 0
        reminderTime = calendar.date(from: components)
    }
    
    private func applySelection() {
        scheduledDate = Calendar.current.startOfDay(for: selectedDate)
        
        if includeTime {
            // Combine selected date with selected time
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: selectedTime)
            
            var combined = DateComponents()
            combined.year = dateComponents.year
            combined.month = dateComponents.month
            combined.day = dateComponents.day
            combined.hour = timeComponents.hour
            combined.minute = timeComponents.minute
            
            reminderTime = calendar.date(from: combined)
        } else {
            reminderTime = nil
        }
    }
}

// MARK: - Menu Label View
struct DateReminderMenuLabel: View {
    let scheduledDate: Date?
    let reminderTime: Date?
    var style: LabelStyle = .pill
    
    enum LabelStyle {
        case pill
        case inline
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: reminderTime != nil ? "bell.badge" : "calendar")
                .foregroundStyle(scheduledDate != nil ? .blue : .secondary)
            
            if let date = scheduledDate {
                if let time = reminderTime {
                    // Show both date and time
                    Text(time, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .foregroundStyle(.primary)
                } else {
                    // Show only date
                    Text(date, format: .dateTime.month(.abbreviated).day())
                        .foregroundStyle(.primary)
                }
            } else if style == .pill {
                Text("When")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.caption)
        .if(style == .pill) { view in
            view
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))
                .cornerRadius(6)
        }
    }
}

// Helper extension for conditional modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    IntegratedDateReminderPicker(
        scheduledDate: .constant(nil),
        reminderTime: .constant(nil)
    )
}
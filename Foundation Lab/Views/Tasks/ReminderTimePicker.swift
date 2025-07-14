//
//  ReminderTimePicker.swift
//  Foundation Lab
//
//  Created by Assistant on 7/14/25.
//

import SwiftUI

struct ReminderTimePicker: View {
    @Binding var reminderTime: Date?
    @Binding var hasReminder: Bool
    let scheduledDate: Date?
    
    @State private var showTimePicker = false
    @State private var tempTime = Date()
    
    var body: some View {
        HStack {
            Label("Reminder", systemImage: "bell")
            
            Spacer()
            
            if hasReminder {
                Button {
                    showTimePicker = true
                } label: {
                    Text(reminderTime?.formatted(date: .omitted, time: .shortened) ?? "Set Time")
                        .foregroundColor(.blue)
                }
                
                Button {
                    hasReminder = false
                    reminderTime = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            } else {
                Toggle("", isOn: $hasReminder)
                    .labelsHidden()
                    .onChange(of: hasReminder) { _, enabled in
                        if enabled && scheduledDate != nil {
                            // Set default reminder time to 9 AM
                            let calendar = Calendar.current
                            var components = calendar.dateComponents([.year, .month, .day], from: scheduledDate!)
                            components.hour = 9
                            components.minute = 0
                            reminderTime = calendar.date(from: components)
                            showTimePicker = true
                        }
                    }
            }
        }
        .disabled(scheduledDate == nil)
        .foregroundColor(scheduledDate == nil ? .secondary : .primary)
        .sheet(isPresented: $showTimePicker) {
            ReminderTimePickerSheet(
                reminderTime: $reminderTime,
                scheduledDate: scheduledDate ?? Date()
            )
        }
    }
}

struct ReminderTimePickerSheet: View {
    @Binding var reminderTime: Date?
    let scheduledDate: Date
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTime: Date
    
    init(reminderTime: Binding<Date?>, scheduledDate: Date) {
        self._reminderTime = reminderTime
        self.scheduledDate = scheduledDate
        
        // Initialize with existing reminder time or default to 9 AM
        if let existingTime = reminderTime.wrappedValue {
            self._selectedTime = State(initialValue: existingTime)
        } else {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: scheduledDate)
            components.hour = 9
            components.minute = 0
            self._selectedTime = State(initialValue: calendar.date(from: components) ?? Date())
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set reminder time for")
                    .font(.headline)
                
                Text(scheduledDate.formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                DatePicker(
                    "Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                // Quick time options
                VStack(spacing: 12) {
                    Text("Quick Options")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        QuickTimeButton(time: "8:00 AM", hour: 8, minute: 0, selectedTime: $selectedTime)
                        QuickTimeButton(time: "9:00 AM", hour: 9, minute: 0, selectedTime: $selectedTime)
                        QuickTimeButton(time: "12:00 PM", hour: 12, minute: 0, selectedTime: $selectedTime)
                        QuickTimeButton(time: "5:00 PM", hour: 17, minute: 0, selectedTime: $selectedTime)
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reminder Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Set") {
                        reminderTime = selectedTime
                        dismiss()
                    }
                }
            }
        }
    }
}

struct QuickTimeButton: View {
    let time: String
    let hour: Int
    let minute: Int
    @Binding var selectedTime: Date
    
    var body: some View {
        Button {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: selectedTime)
            components.hour = hour
            components.minute = minute
            if let newTime = calendar.date(from: components) {
                selectedTime = newTime
            }
        } label: {
            Text(time)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}
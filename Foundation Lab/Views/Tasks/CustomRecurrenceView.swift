//
//  CustomRecurrenceView.swift
//  FoundationLab
//
//  Created by Assistant on 7/12/25.
//

import SwiftUI

struct CustomRecurrenceView: View {
    @Binding var customRecurrence: CustomRecurrence?
    @Binding var isPresented: Bool
    
    @State private var interval: Int = 1
    @State private var selectedUnit: CustomRecurrence.TimeUnit = .day
    @State private var selectedWeekdays: Set<Int> = []
    @State private var monthlyOption: CustomRecurrence.MonthlyOption = .sameDay
    @State private var dayOfMonth: Int = Calendar.current.component(.day, from: Date())
    @State private var endOption: EndOption = .never
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var occurrenceCount: Int = 10
    
    enum EndOption: String, CaseIterable {
        case never = "Never"
        case onDate = "On Date"
        case afterOccurrences = "After Occurrences"
    }
    
    init(customRecurrence: Binding<CustomRecurrence?>, isPresented: Binding<Bool>) {
        self._customRecurrence = customRecurrence
        self._isPresented = isPresented
        
        // Initialize state from existing custom recurrence
        if let existing = customRecurrence.wrappedValue {
            _interval = State(initialValue: existing.interval)
            _selectedUnit = State(initialValue: existing.unit)
            _selectedWeekdays = State(initialValue: existing.selectedDays ?? [])
            _monthlyOption = State(initialValue: existing.monthlyOption ?? .sameDay)
            _dayOfMonth = State(initialValue: existing.dayOfMonth ?? Calendar.current.component(.day, from: Date()))
            
            if let existingEndDate = existing.endDate {
                _endOption = State(initialValue: .onDate)
                _endDate = State(initialValue: existingEndDate)
            } else if let existingOccurrences = existing.occurrenceCount {
                _endOption = State(initialValue: .afterOccurrences)
                _occurrenceCount = State(initialValue: existingOccurrences)
            } else {
                _endOption = State(initialValue: .never)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Frequency") {
                    HStack {
                        Text("Every")
                        
                        TextField("Interval", value: $interval, format: .number)
                            .frame(width: 60)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                        
                        Picker(selection: $selectedUnit) {
                            ForEach(CustomRecurrence.TimeUnit.allCases, id: \.self) { unit in
                                Text(interval > 1 ? pluralName(for: unit) : singularName(for: unit))
                                    .tag(unit)
                            }
                        } label: {
                            EmptyView()
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()
                    }
                    
                    // Show weekday selection for weekly recurrence
                    if selectedUnit == .week {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Repeat on")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(0..<7) { dayIndex in
                                    WeekdayButton(
                                        dayIndex: dayIndex,
                                        isSelected: selectedWeekdays.contains(dayIndex),
                                        action: { toggleWeekday(dayIndex) }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Show day selection for monthly recurrence
                    if selectedUnit == .month {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Monthly on", selection: $monthlyOption) {
                                Text("Day \(dayOfMonth)").tag(CustomRecurrence.MonthlyOption.sameDay)
                                Text("Last day of month").tag(CustomRecurrence.MonthlyOption.lastDay)
                            }
                            .pickerStyle(.segmented)
                            
                            if monthlyOption == .sameDay {
                                HStack {
                                    Text("Day of month:")
                                    Picker("Day", selection: $dayOfMonth) {
                                        ForEach(1...31, id: \.self) { day in
                                            Text("\(day)").tag(day)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                        }
                    }
                }
                
                Section("End") {
                    Picker("End", selection: $endOption) {
                        ForEach(EndOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch endOption {
                    case .never:
                        EmptyView()
                    case .onDate:
                        DatePicker(
                            "End Date",
                            selection: $endDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    case .afterOccurrences:
                        HStack {
                            Text("End after")
                            TextField("Count", value: $occurrenceCount, format: .number)
                                .frame(width: 60)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            Text("occurrences")
                        }
                    }
                }
                
                Section {
                    Text(recurrenceDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Custom Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveCustomRecurrence()
                        isPresented = false
                    }
                    .disabled(interval < 1)
                }
            }
        }
    }
    
    private func toggleWeekday(_ dayIndex: Int) {
        if selectedWeekdays.contains(dayIndex) {
            selectedWeekdays.remove(dayIndex)
        } else {
            selectedWeekdays.insert(dayIndex)
        }
    }
    
    private func saveCustomRecurrence() {
        var newRecurrence = CustomRecurrence(
            interval: interval,
            unit: selectedUnit,
            selectedDays: selectedUnit == .week && !selectedWeekdays.isEmpty ? selectedWeekdays : nil,
            monthlyOption: selectedUnit == .month ? monthlyOption : nil,
            dayOfMonth: selectedUnit == .month && monthlyOption == .sameDay ? dayOfMonth : nil,
            endDate: nil,
            occurrenceCount: nil
        )
        
        switch endOption {
        case .never:
            break
        case .onDate:
            newRecurrence.endDate = endDate
        case .afterOccurrences:
            newRecurrence.occurrenceCount = occurrenceCount
        }
        
        customRecurrence = newRecurrence
    }
    
    private var recurrenceDescription: String {
        var description = "Repeats every "
        
        if interval == 1 {
            description += singularName(for: selectedUnit)
        } else {
            description += "\(interval) \(pluralName(for: selectedUnit))"
        }
        
        if selectedUnit == .week && !selectedWeekdays.isEmpty {
            let dayNames = selectedWeekdays.sorted().map { weekdayName(for: $0) }
            description += " on \(dayNames.joined(separator: ", "))"
        }
        
        if selectedUnit == .month {
            if monthlyOption == .sameDay {
                description += " on day \(dayOfMonth)"
            } else {
                description += " on the last day"
            }
        }
        
        switch endOption {
        case .never:
            description += ", forever"
        case .onDate:
            description += ", until \(endDate.formatted(date: .abbreviated, time: .omitted))"
        case .afterOccurrences:
            description += ", \(occurrenceCount) times"
        }
        
        return description
    }
    
    private func singularName(for unit: CustomRecurrence.TimeUnit) -> String {
        switch unit {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        }
    }
    
    private func pluralName(for unit: CustomRecurrence.TimeUnit) -> String {
        switch unit {
        case .day: return "days"
        case .week: return "weeks"
        case .month: return "months"
        case .year: return "years"
        }
    }
    
    private func weekdayName(for index: Int) -> String {
        let formatter = DateFormatter()
        return formatter.weekdaySymbols[index]
    }
}

struct WeekdayButton: View {
    let dayIndex: Int
    let isSelected: Bool
    let action: () -> Void
    
    private var daySymbol: String {
        let formatter = DateFormatter()
        return String(formatter.shortWeekdaySymbols[dayIndex].prefix(1))
    }
    
    var body: some View {
        Button(action: action) {
            Text(daySymbol)
                .font(.caption)
                .fontWeight(.medium)
                .frame(width: 36, height: 36)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CustomRecurrenceView(
        customRecurrence: .constant(nil),
        isPresented: .constant(true)
    )
}
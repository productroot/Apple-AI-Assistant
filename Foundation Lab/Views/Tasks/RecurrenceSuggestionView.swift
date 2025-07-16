import SwiftUI

struct RecurrenceSuggestionView: View {
    var viewModel: TasksViewModel
    @State private var detectedPatterns: [RecurrencePatternDetector.PatternMatch] = []
    @State private var isAnalyzing = false
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisResult = ""
    @State private var selectedPattern: RecurrencePatternDetector.PatternMatch?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("Recurring Task Detection")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("AI analyzes your completed tasks to find patterns")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    
                    // Analyze Button
                    if detectedPatterns.isEmpty && !isAnalyzing {
                        Button {
                            analyzePatterns()
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                Text("Analyze Task History")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Loading State
                    if isAnalyzing {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Analyzing your task history...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    // Detected Patterns
                    if !detectedPatterns.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Detected Patterns")
                                    .font(.headline)
                                Spacer()
                                Text("\(detectedPatterns.count) found")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            ForEach(detectedPatterns, id: \.taskTitle) { pattern in
                                PatternCard(
                                    pattern: pattern,
                                    onApply: {
                                        applyRecurrence(pattern)
                                    },
                                    onDetail: {
                                        selectedPattern = pattern
                                    }
                                )
                            }
                        }
                    }
                    
                    // AI Deep Analysis
                    if !detectedPatterns.isEmpty {
                        Button {
                            performAIAnalysis()
                        } label: {
                            HStack {
                                Image(systemName: "brain")
                                Text("Get AI Insights")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .foregroundColor(.purple)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Smart Recurrence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedPattern) { pattern in
                PatternDetailView(pattern: pattern, viewModel: viewModel)
            }
            .sheet(isPresented: $showingAIAnalysis) {
                AIAnalysisView(
                    analysis: aiAnalysisResult,
                    patterns: detectedPatterns,
                    onApplyAll: applyAllSuggestions
                )
            }
        }
    }
    
    private func analyzePatterns() {
        isAnalyzing = true
        
        // Analyze patterns in background
        Task {
            // Get completed tasks from the last 90 days
            let calendar = Calendar.current
            let ninetyDaysAgo = calendar.date(byAdding: .day, value: -90, to: Date())!
            
            let completedTasks = viewModel.tasks.filter { task in
                task.isCompleted &&
                task.completionDate != nil &&
                task.completionDate! > ninetyDaysAgo
            }
            
            print("🔍 Analyzing \(completedTasks.count) completed tasks for patterns")
            
            let patterns = RecurrencePatternDetector.detectPatterns(from: completedTasks)
            
            await MainActor.run {
                detectedPatterns = patterns
                isAnalyzing = false
                print("✅ Found \(patterns.count) potential recurring patterns")
            }
        }
    }
    
    private func applyRecurrence(_ pattern: RecurrencePatternDetector.PatternMatch) {
        // Create a new recurring task based on the pattern
        let newTask = TodoTask(
            title: pattern.taskTitle,
            recurrenceRule: pattern.suggestedRule
        )
        
        viewModel.addTask(newTask)
        
        // Remove from detected patterns
        detectedPatterns.removeAll { $0.taskTitle == pattern.taskTitle }
        
        print("✅ Created recurring task: \(pattern.taskTitle) with rule: \(pattern.suggestedRule.displayName)")
    }
    
    private func performAIAnalysis() {
        showingAIAnalysis = true
        
        Task {
            do {
                aiAnalysisResult = try await viewModel.analyzeRecurrencePatterns(detectedPatterns)
            } catch {
                print("❌ AI analysis failed: \(error)")
                aiAnalysisResult = "Failed to analyze patterns. Please try again."
            }
        }
    }
    
    private func applyAllSuggestions() {
        for pattern in detectedPatterns where pattern.confidence != .low {
            applyRecurrence(pattern)
        }
        dismiss()
    }
}

struct PatternCard: View {
    let pattern: RecurrencePatternDetector.PatternMatch
    let onApply: () -> Void
    let onDetail: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pattern.taskTitle)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack(spacing: 8) {
                        Label(pattern.suggestedRule.displayName, systemImage: pattern.suggestedRule.icon)
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Text(pattern.confidence.emoji)
                            Text(pattern.confidence.description)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    Button("Apply", action: onApply)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    
                    Button("Details", action: onDetail)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            }
            
            HStack(spacing: 4) {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text(pattern.reason)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            // Visual timeline
            if pattern.occurrences.count > 2 {
                TimelineView(dates: pattern.occurrences)
                    .frame(height: 40)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct TimelineView: View {
    let dates: [Date]
    
    var body: some View {
        GeometryReader { geometry in
            let sortedDates = dates.sorted()
            let firstDate = sortedDates.first!
            let lastDate = sortedDates.last!
            let totalInterval = lastDate.timeIntervalSince(firstDate)
            
            ZStack(alignment: .leading) {
                // Timeline line
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
                
                // Date markers
                ForEach(sortedDates, id: \.self) { date in
                    let position = totalInterval > 0 ? 
                        CGFloat(date.timeIntervalSince(firstDate) / totalInterval) : 0
                    
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)
                        .position(
                            x: position * geometry.size.width,
                            y: geometry.size.height / 2
                        )
                }
            }
        }
    }
}

struct PatternDetailView: View {
    let pattern: RecurrencePatternDetector.PatternMatch
    let viewModel: TasksViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Pattern Information") {
                    LabeledContent("Task", value: pattern.taskTitle)
                    LabeledContent("Suggested Recurrence", value: pattern.suggestedRule.displayName)
                    LabeledContent("Confidence", value: pattern.confidence.description)
                    LabeledContent("Occurrences", value: "\(pattern.occurrences.count)")
                    
                    if let avgInterval = pattern.averageInterval {
                        LabeledContent("Average Interval", value: formatInterval(avgInterval))
                    }
                }
                
                Section("Occurrence History") {
                    ForEach(pattern.occurrences.sorted().reversed(), id: \.self) { date in
                        Text(date.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                    }
                }
                
                Section("Actions") {
                    Button {
                        // Apply recurrence
                        dismiss()
                    } label: {
                        Label("Apply This Recurrence", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        // Customize recurrence
                    } label: {
                        Label("Customize Recurrence", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .navigationTitle("Pattern Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatInterval(_ interval: TimeInterval) -> String {
        let days = Int(interval / 86400)
        if days == 1 {
            return "1 day"
        } else if days < 7 {
            return "\(days) days"
        } else if days == 7 {
            return "1 week"
        } else if days < 30 {
            return "\(days / 7) weeks"
        } else if days < 365 {
            return "\(days / 30) months"
        } else {
            return "\(days / 365) year(s)"
        }
    }
}

struct AIAnalysisView: View {
    let analysis: String
    let patterns: [RecurrencePatternDetector.PatternMatch]
    let onApplyAll: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(analysis)
                        .padding()
                    
                    if patterns.contains(where: { $0.confidence != .low }) {
                        Button {
                            onApplyAll()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Apply All High-Confidence Patterns")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
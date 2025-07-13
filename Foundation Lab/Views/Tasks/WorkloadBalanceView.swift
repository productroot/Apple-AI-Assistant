import SwiftUI
import Charts

struct WorkloadBalanceView: View {
    var viewModel: TasksViewModel
    @State private var selectedDateRange = 7 // Days to show
    @State private var workloads: [WorkloadAnalyzer.DailyWorkload] = []
    @State private var insights: WorkloadAnalyzer.WorkloadInsight?
    @State private var showingAISuggestions = false
    @State private var isGeneratingSuggestions = false
    @State private var aiSuggestions: String = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Date Range Selector
                    Picker("Date Range", selection: $selectedDateRange) {
                        Text("Next 7 days").tag(7)
                        Text("Next 14 days").tag(14)
                        Text("Next 30 days").tag(30)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Workload Chart
                    if !workloads.isEmpty {
                        workloadChart
                            .frame(height: 250)
                            .padding(.horizontal)
                    }
                    
                    // Summary Stats
                    if let insights = insights {
                        summarySection(insights)
                    }
                    
                    // Overloaded Days Warning
                    if let insights = insights, !insights.overloadedDays.isEmpty {
                        overloadedDaysSection(insights.overloadedDays)
                    }
                    
                    // AI Suggestions
                    if let insights = insights, !insights.suggestedMoves.isEmpty {
                        suggestedMovesSection(insights.suggestedMoves)
                    }
                    
                    // AI Analysis Button
                    aiAnalysisButton
                }
                .padding(.vertical)
            }
            .navigationTitle("Workload Balance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                analyzeWorkload()
            }
            .onChange(of: selectedDateRange) { oldValue, newValue in
                analyzeWorkload()
            }
            .sheet(isPresented: $showingAISuggestions) {
                AISuggestionsView(
                    suggestions: aiSuggestions,
                    isLoading: isGeneratingSuggestions,
                    onApply: { suggestion in
                        // Apply AI suggestion
                        print("Applying AI suggestion: \(suggestion)")
                    }
                )
            }
        }
    }
    
    private var workloadChart: some View {
        Chart(workloads) { workload in
            BarMark(
                x: .value("Date", workload.date, unit: .day),
                y: .value("Workload", workload.workloadScore)
            )
            .foregroundStyle(workload.workloadLevel.color.gradient)
            .annotation(position: .top) {
                VStack(spacing: 2) {
                    Text(workload.workloadLevel.emoji)
                        .font(.caption)
                    if workload.taskCount > 0 {
                        Text("\(workload.taskCount)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Add a reference line for "comfortable" workload
            RuleMark(y: .value("Comfortable", 60))
                .foregroundStyle(.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYAxisLabel("Workload Score")
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
    
    private func summarySection(_ insights: WorkloadAnalyzer.WorkloadInsight) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)
                .padding(.horizontal)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Average Load",
                    value: String(format: "%.0f%%", insights.averageWorkloadScore),
                    color: colorForScore(insights.averageWorkloadScore)
                )
                
                if let peakDay = insights.peakDay {
                    StatCard(
                        title: "Peak Day",
                        value: peakDay.date.formatted(date: .abbreviated, time: .omitted),
                        color: peakDay.workloadLevel.color
                    )
                }
                
                StatCard(
                    title: "Overloaded",
                    value: "\(insights.overloadedDays.count) days",
                    color: insights.overloadedDays.isEmpty ? .green : .red
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func overloadedDaysSection(_ overloadedDays: [WorkloadAnalyzer.DailyWorkload]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Overloaded Days", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            ForEach(overloadedDays, id: \.date) { workload in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workload.date.formatted(date: .complete, time: .omitted))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 12) {
                            Label("\(workload.taskCount) tasks", systemImage: "checklist")
                                .font(.caption)
                            
                            Label(WorkloadAnalyzer.formatDuration(workload.totalEstimatedDuration), systemImage: "clock")
                                .font(.caption)
                            
                            if workload.highPriorityCount > 0 {
                                Label("\(workload.highPriorityCount) urgent", systemImage: "exclamationmark")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(workload.workloadLevel.emoji)
                        .font(.title2)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private func suggestedMovesSection(_ moves: [WorkloadAnalyzer.TaskMove]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suggested Moves", systemImage: "arrow.right.arrow.left")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(moves, id: \.task.id) { move in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(move.task.title)
                            .font(.subheadline)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(move.fromDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.red)
                            Image(systemName: "arrow.right")
                            Text(move.toDate.formatted(date: .abbreviated, time: .omitted))
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Apply") {
                        applyTaskMove(move)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    private var aiAnalysisButton: some View {
        Button {
            generateAISuggestions()
        } label: {
            HStack {
                Image(systemName: "sparkles")
                Text("Get AI Suggestions")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.horizontal)
        .disabled(isGeneratingSuggestions)
    }
    
    private func analyzeWorkload() {
        let calendar = Calendar.current
        let startDate = Date()
        guard let endDate = calendar.date(byAdding: .day, value: selectedDateRange, to: startDate) else { return }
        
        let dateRange = startDate...endDate
        workloads = WorkloadAnalyzer.analyzeWorkload(tasks: viewModel.tasks, dateRange: dateRange)
        insights = WorkloadAnalyzer.generateInsights(from: workloads)
        
        print("📊 Analyzed workload for \(selectedDateRange) days")
        print("📊 Found \(insights?.overloadedDays.count ?? 0) overloaded days")
    }
    
    private func applyTaskMove(_ move: WorkloadAnalyzer.TaskMove) {
        guard let index = viewModel.tasks.firstIndex(where: { $0.id == move.task.id }) else { return }
        
        var updatedTask = viewModel.tasks[index]
        updatedTask.scheduledDate = move.toDate
        viewModel.updateTask(updatedTask)
        
        // Re-analyze after the change
        analyzeWorkload()
        
        print("✅ Moved task '\(move.task.title)' to \(move.toDate)")
    }
    
    private func generateAISuggestions() {
        guard let insights = insights else { return }
        
        isGeneratingSuggestions = true
        showingAISuggestions = true
        
        Task {
            do {
                aiSuggestions = try await viewModel.generateWorkloadSuggestions(
                    workloads: workloads,
                    insights: insights
                )
                isGeneratingSuggestions = false
            } catch {
                print("❌ Error generating AI suggestions: \(error)")
                aiSuggestions = "Failed to generate suggestions. Please try again."
                isGeneratingSuggestions = false
            }
        }
    }
    
    private func colorForScore(_ score: Double) -> Color {
        switch score {
        case 0..<30: return .green
        case 30..<60: return .yellow
        case 60..<80: return .orange
        default: return .red
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AISuggestionsView: View {
    let suggestions: String
    let isLoading: Bool
    let onApply: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    ProgressView("Analyzing your workload...")
                        .padding()
                } else {
                    Text(suggestions)
                        .padding()
                }
            }
            .navigationTitle("AI Suggestions")
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
import SwiftUI
import Charts

struct TaskInsightsDashboardView: View {
    let viewModel: TasksViewModel
    @State private var dashboard: TaskInsightsAnalyzer.InsightsDashboard?
    @State private var isAnalyzing = false
    @State private var selectedInsight: TaskInsightsAnalyzer.ProductivityInsight?
    @State private var showingAIAnalysis = false
    @State private var aiAnalysisResult = ""
    @State private var selectedTimeRange = TimeRange.last30Days
    @Environment(\.dismiss) private var dismiss
    
    enum TimeRange: String, CaseIterable {
        case last7Days = "7 Days"
        case last30Days = "30 Days"
        case last90Days = "90 Days"
        
        var days: Int {
            switch self {
            case .last7Days: return 7
            case .last30Days: return 30
            case .last90Days: return 90
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isAnalyzing {
                    AnalyzingView()
                } else if let dashboard = dashboard {
                    VStack(spacing: 20) {
                        // Header with overall score
                        DashboardHeaderView(
                            score: dashboard.overallProductivityScore,
                            streak: dashboard.streakDays
                        )
                        
                        // Time range picker
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .onChange(of: selectedTimeRange) { _, _ in
                            analyzeProductivity()
                        }
                        
                        // Key Insights
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Key Insights")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(dashboard.insights.prefix(5)) { insight in
                                        InsightCardView(insight: insight)
                                            .onTapGesture {
                                                selectedInsight = insight
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Time of Day Analysis
                        if !dashboard.timeAnalysis.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Productivity by Time of Day")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TimeOfDayChartView(timeAnalysis: dashboard.timeAnalysis)
                                    .frame(height: 250)
                                    .padding(.horizontal)
                            }
                        }
                        
                        // Project Health
                        if !dashboard.projectHealthMetrics.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Project Health")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button {
                                        // Navigate to projects
                                    } label: {
                                        Text("View All")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal)
                                
                                VStack(spacing: 8) {
                                    ForEach(dashboard.projectHealthMetrics.prefix(5)) { metric in
                                        ProjectHealthRowView(metric: metric)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // AI Suggestions
                        if !dashboard.suggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Label("AI Recommendations", systemImage: "sparkles")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Button {
                                        showingAIAnalysis = true
                                        performDeepAnalysis()
                                    } label: {
                                        Text("Deep Analysis")
                                            .font(.caption)
                                            .foregroundColor(.purple)
                                    }
                                }
                                .padding(.horizontal)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(dashboard.suggestions, id: \.self) { suggestion in
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "lightbulb.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                            
                                            Text(suggestion)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                } else {
                    EmptyInsightsView {
                        analyzeProductivity()
                    }
                }
            }
            .navigationTitle("Task Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if dashboard != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            analyzeProductivity()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .sheet(item: $selectedInsight) { insight in
                InsightDetailView(insight: insight)
            }
            .sheet(isPresented: $showingAIAnalysis) {
                AIInsightsAnalysisView(
                    analysis: aiAnalysisResult,
                    dashboard: dashboard
                )
            }
            .onAppear {
                if dashboard == nil {
                    analyzeProductivity()
                }
            }
        }
    }
    
    private func analyzeProductivity() {
        isAnalyzing = true
        
        Task {
            // Filter tasks based on selected time range
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())!
            let relevantTasks = viewModel.tasks.filter { task in
                return task.createdAt > cutoffDate
            }
            
            print("📊 Analyzing productivity for \(relevantTasks.count) tasks over \(selectedTimeRange.days) days")
            
            let dashboard = TaskInsightsAnalyzer.analyzeProductivity(
                tasks: relevantTasks,
                projects: viewModel.projects
            )
            
            await MainActor.run {
                self.dashboard = dashboard
                isAnalyzing = false
                print("✅ Generated \(dashboard.insights.count) insights")
            }
        }
    }
    
    private func performDeepAnalysis() {
        Task {
            do {
                if let dashboard = dashboard {
                    aiAnalysisResult = try await viewModel.generateProductivityInsights(dashboard)
                }
            } catch {
                print("❌ Deep analysis failed: \(error)")
                aiAnalysisResult = "Failed to generate deep insights. Please try again."
            }
        }
    }
}

struct DashboardHeaderView: View {
    let score: Double
    let streak: Int
    
    var scoreDescription: String {
        switch score {
        case 0.8...1.0: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        case 0.2..<0.4: return "Needs Improvement"
        default: return "Just Getting Started"
        }
    }
    
    var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .blue
        case 0.4..<0.6: return .yellow
        case 0.2..<0.4: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Productivity Score
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: score)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [scoreColor.opacity(0.7), scoreColor]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.0), value: score)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(score * 100))")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(scoreColor)
                        
                        Text(scoreDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text("Productivity Score")
                    .font(.headline)
            }
            
            // Streak Counter
            if streak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(streak) Day Streak")
                            .font(.headline)
                        
                        Text("Keep up the great work!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct InsightCardView: View {
    let insight: TaskInsightsAnalyzer.ProductivityInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: insight.type.icon)
                    .foregroundColor(insight.type.color)
                    .font(.title3)
                
                Spacer()
                
                Image(systemName: insight.trend.icon)
                    .foregroundColor(insight.trend.color)
                    .font(.caption)
            }
            
            Text(insight.title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(insight.value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(insight.description)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(width: 160, height: 120)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TimeOfDayChartView: View {
    let timeAnalysis: [TaskInsightsAnalyzer.TimeOfDayAnalysis]
    
    var body: some View {
        Chart(timeAnalysis, id: \.hour) { data in
            BarMark(
                x: .value("Time", data.timeLabel),
                y: .value("Tasks", data.completionCount)
            )
            .foregroundStyle(
                data.efficiency > 1.2 ? Color.green :
                data.efficiency > 0.8 ? Color.blue : Color.orange
            )
            .annotation(position: .top) {
                if data.completionCount > 0 {
                    Text("\(data.completionCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 3)) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel()
            }
        }
        .chartLegend(position: .bottom) {
            HStack(spacing: 16) {
                Label("High Efficiency", systemImage: "circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Label("Normal", systemImage: "circle.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Label("Low Efficiency", systemImage: "circle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
}

struct ProjectHealthRowView: View {
    let metric: TaskInsightsAnalyzer.ProjectHealthMetric
    
    var body: some View {
        HStack {
            Circle()
                .fill(metric.project.displayColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.project.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(metric.healthStatus)
                        .font(.caption)
                        .foregroundColor(metric.healthColor)
                    
                    if !metric.risks.isEmpty {
                        Text("• \(metric.risks.first!)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Health indicator
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: metric.health)
                    .stroke(metric.healthColor, lineWidth: 3)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(metric.health * 100))")
                    .font(.caption2)
                    .fontWeight(.bold)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct AnalyzingView: View {
    @State private var rotation = 0.0
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color.blue.opacity(0.3 - Double(index) * 0.1), lineWidth: 2)
                        .frame(width: 60 + CGFloat(index) * 20, height: 60 + CGFloat(index) * 20)
                        .scaleEffect(rotation / 360)
                }
                
                Image(systemName: "brain")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
            }
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
            
            Text("Analyzing Your Productivity")
                .font(.headline)
            
            Text("AI is examining your task patterns...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyInsightsView: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .symbolRenderingMode(.hierarchical)
            
            Text("Productivity Insights")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get AI-powered insights about your productivity patterns and task completion habits")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                onAnalyze()
            } label: {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Analyze My Productivity")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct InsightDetailView: View {
    let insight: TaskInsightsAnalyzer.ProductivityInsight
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: insight.type.icon)
                        .font(.system(size: 60))
                        .foregroundColor(insight.type.color)
                    
                    Text(insight.value)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(insight.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Insight")
                        .font(.headline)
                    
                    Text(insight.description)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Label("Trend: \(insight.trend.description)", systemImage: insight.trend.icon)
                            .foregroundColor(insight.trend.color)
                        
                        Spacer()
                        
                        Text("Confidence: \(Int(insight.confidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Recommendation
                if let recommendation = insight.recommendation {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Recommendation", systemImage: "lightbulb.fill")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        
                        Text(recommendation)
                            .padding()
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationTitle("Insight Details")
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

struct AIInsightsAnalysisView: View {
    let analysis: String
    let dashboard: TaskInsightsAnalyzer.InsightsDashboard?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !analysis.isEmpty {
                        Text(analysis)
                            .padding()
                    } else {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            
                            Text("AI is generating deep insights...")
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
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
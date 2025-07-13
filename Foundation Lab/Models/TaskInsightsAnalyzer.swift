import Foundation
import SwiftUI

struct TaskInsightsAnalyzer {
    struct ProductivityInsight: Identifiable {
        let id = UUID()
        let type: InsightType
        let title: String
        let value: String
        let description: String
        let trend: Trend
        let confidence: Double
        let actionable: Bool
        let recommendation: String?
        
        enum InsightType {
            case completionRate
            case peakProductivity
            case taskDuration
            case projectHealth
            case workPattern
            case efficiency
            case procrastination
            case momentum
            
            var icon: String {
                switch self {
                case .completionRate: return "checkmark.circle.fill"
                case .peakProductivity: return "sunrise.fill"
                case .taskDuration: return "clock.fill"
                case .projectHealth: return "heart.fill"
                case .workPattern: return "calendar"
                case .efficiency: return "speedometer"
                case .procrastination: return "hourglass"
                case .momentum: return "arrow.up.right"
                }
            }
            
            var color: Color {
                switch self {
                case .completionRate: return .green
                case .peakProductivity: return .orange
                case .taskDuration: return .blue
                case .projectHealth: return .red
                case .workPattern: return .purple
                case .efficiency: return .teal
                case .procrastination: return .yellow
                case .momentum: return .indigo
                }
            }
        }
        
        enum Trend {
            case improving
            case stable
            case declining
            case notEnoughData
            
            var description: String {
                switch self {
                case .improving: return "Improving"
                case .stable: return "Stable"
                case .declining: return "Declining"
                case .notEnoughData: return "Not enough data"
                }
            }
            
            var icon: String {
                switch self {
                case .improving: return "arrow.up.right"
                case .stable: return "arrow.right"
                case .declining: return "arrow.down.right"
                case .notEnoughData: return "questionmark"
                }
            }
            
            var color: Color {
                switch self {
                case .improving: return .green
                case .stable: return .blue
                case .declining: return .red
                case .notEnoughData: return .gray
                }
            }
        }
    }
    
    struct TimeOfDayAnalysis {
        let hour: Int
        let completionCount: Int
        let averageDuration: TimeInterval
        let efficiency: Double // 0.0 to 1.0
        
        var timeLabel: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "ha"
            
            var components = DateComponents()
            components.hour = hour
            
            if let date = Calendar.current.date(from: components) {
                return formatter.string(from: date)
            }
            return "\(hour):00"
        }
    }
    
    struct ProjectHealthMetric: Identifiable {
        var id: UUID { project.id }
        let project: Project
        let health: Double // 0.0 to 1.0
        let completionRate: Double
        let overdueCount: Int
        let momentum: Double // Recent activity level
        let estimatedCompletion: Date?
        let risks: [String]
        
        var healthStatus: String {
            switch health {
            case 0.8...1.0: return "Excellent"
            case 0.6..<0.8: return "Good"
            case 0.4..<0.6: return "Fair"
            case 0.2..<0.4: return "At Risk"
            default: return "Critical"
            }
        }
        
        var healthColor: Color {
            switch health {
            case 0.8...1.0: return .green
            case 0.6..<0.8: return .blue
            case 0.4..<0.6: return .yellow
            case 0.2..<0.4: return .orange
            default: return .red
            }
        }
    }
    
    struct InsightsDashboard {
        let insights: [ProductivityInsight]
        let timeAnalysis: [TimeOfDayAnalysis]
        let projectHealthMetrics: [ProjectHealthMetric]
        let overallProductivityScore: Double
        let streakDays: Int
        let suggestions: [String]
    }
    
    static func analyzeProductivity(tasks: [TodoTask], projects: [Project]) -> InsightsDashboard {
        let calendar = Calendar.current
        let now = Date()
        
        // Filter tasks for analysis
        let completedTasks = tasks.filter { $0.isCompleted }
        let recentTasks = tasks.filter { task in
            let date = task.completionDate ?? task.createdAt
            return calendar.dateComponents([.day], from: date, to: now).day! <= 30
        }
        
        var insights: [ProductivityInsight] = []
        
        // Completion Rate Analysis
        let completionRate = calculateCompletionRate(tasks: recentTasks)
        insights.append(ProductivityInsight(
            type: .completionRate,
            title: "Completion Rate",
            value: "\(Int(completionRate * 100))%",
            description: "Your task completion rate over the last 30 days",
            trend: determineTrend(current: completionRate, previous: calculateCompletionRate(tasks: tasks, daysAgo: 60)),
            confidence: 0.9,
            actionable: completionRate < 0.7,
            recommendation: completionRate < 0.7 ? "Consider breaking down large tasks into smaller, manageable pieces" : nil
        ))
        
        // Peak Productivity Time
        let timeAnalysis = analyzeTimeOfDay(tasks: completedTasks)
        if let peakHour = timeAnalysis.max(by: { $0.efficiency < $1.efficiency }) {
            insights.append(ProductivityInsight(
                type: .peakProductivity,
                title: "Peak Productivity",
                value: peakHour.timeLabel,
                description: "You complete tasks \(Int(peakHour.efficiency * 100 - 100))% faster at this time",
                trend: .stable,
                confidence: 0.8,
                actionable: true,
                recommendation: "Schedule your most important tasks around \(peakHour.timeLabel)"
            ))
        }
        
        // Average Task Duration
        let avgDuration = calculateAverageDuration(tasks: completedTasks)
        let previousAvgDuration = calculateAverageDuration(tasks: completedTasks.filter { task in
            if let date = task.completionDate {
                return calendar.dateComponents([.day], from: date, to: now).day! > 30
            }
            return false
        })
        
        insights.append(ProductivityInsight(
            type: .taskDuration,
            title: "Average Task Time",
            value: formatDuration(avgDuration),
            description: "Time spent on average per task",
            trend: avgDuration < previousAvgDuration ? .improving : .declining,
            confidence: 0.85,
            actionable: avgDuration > 3600,
            recommendation: avgDuration > 3600 ? "Your tasks take longer than an hour on average. Consider time-boxing or using the Pomodoro technique" : nil
        ))
        
        // Work Pattern Analysis
        let workPattern = analyzeWorkPattern(tasks: recentTasks)
        insights.append(ProductivityInsight(
            type: .workPattern,
            title: "Work Pattern",
            value: workPattern.pattern,
            description: workPattern.description,
            trend: .stable,
            confidence: 0.7,
            actionable: true,
            recommendation: workPattern.recommendation
        ))
        
        // Procrastination Analysis
        let procrastinationScore = analyzeProcrastination(tasks: recentTasks)
        if procrastinationScore > 0.3 {
            insights.append(ProductivityInsight(
                type: .procrastination,
                title: "Task Delay Pattern",
                value: "\(Int(procrastinationScore * 100))%",
                description: "Tasks completed after their scheduled date",
                trend: .declining,
                confidence: 0.75,
                actionable: true,
                recommendation: "Try the 2-minute rule: if a task takes less than 2 minutes, do it immediately"
            ))
        }
        
        // Momentum Analysis
        let momentum = calculateMomentum(tasks: recentTasks)
        insights.append(ProductivityInsight(
            type: .momentum,
            title: "Current Momentum",
            value: momentum > 0.7 ? "Strong" : momentum > 0.4 ? "Moderate" : "Low",
            description: "Your recent task completion momentum",
            trend: momentum > 0.7 ? .improving : momentum < 0.4 ? .declining : .stable,
            confidence: 0.8,
            actionable: momentum < 0.4,
            recommendation: momentum < 0.4 ? "Start with small, easy tasks to build momentum" : nil
        ))
        
        // Project Health Analysis
        let projectHealthMetrics = analyzeProjectHealth(projects: projects, tasks: tasks)
        
        // Calculate overall productivity score
        let overallScore = calculateOverallProductivityScore(
            completionRate: completionRate,
            momentum: momentum,
            procrastination: procrastinationScore
        )
        
        // Calculate streak
        let streakDays = calculateProductivityStreak(tasks: tasks)
        
        // Generate suggestions
        let suggestions = generateSuggestions(
            insights: insights,
            projectHealth: projectHealthMetrics,
            overallScore: overallScore
        )
        
        return InsightsDashboard(
            insights: insights,
            timeAnalysis: timeAnalysis,
            projectHealthMetrics: projectHealthMetrics,
            overallProductivityScore: overallScore,
            streakDays: streakDays,
            suggestions: suggestions
        )
    }
    
    private static func calculateCompletionRate(tasks: [TodoTask], daysAgo: Int = 30) -> Double {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        
        let relevantTasks = tasks.filter { task in
            let date = task.scheduledDate ?? task.createdAt
            return date > cutoffDate
        }
        
        guard !relevantTasks.isEmpty else { return 0 }
        
        let completed = relevantTasks.filter { $0.isCompleted }.count
        return Double(completed) / Double(relevantTasks.count)
    }
    
    private static func analyzeTimeOfDay(tasks: [TodoTask]) -> [TimeOfDayAnalysis] {
        let calendar = Calendar.current
        var hourlyStats: [Int: (count: Int, totalDuration: TimeInterval)] = [:]
        
        for task in tasks {
            guard let completionDate = task.completionDate else { continue }
            let hour = calendar.component(.hour, from: completionDate)
            
            // Calculate actual duration if both startedAt and completionDate exist
            let duration: TimeInterval
            if let startedAt = task.startedAt {
                duration = completionDate.timeIntervalSince(startedAt)
            } else {
                duration = task.estimatedDuration ?? 1800 // Default 30 min
            }
            
            hourlyStats[hour, default: (0, 0)].count += 1
            hourlyStats[hour, default: (0, 0)].totalDuration += duration
        }
        
        // Calculate efficiency for each hour
        let durations = tasks.compactMap { task -> TimeInterval? in
            if let completionDate = task.completionDate, let startedAt = task.startedAt {
                return completionDate.timeIntervalSince(startedAt)
            }
            return task.estimatedDuration
        }
        let avgDuration = durations.isEmpty ? 1800 : durations.reduce(0, +) / Double(durations.count)
        
        return hourlyStats.map { hour, stats in
            let avgHourlyDuration = stats.totalDuration / Double(stats.count)
            let efficiency = avgDuration > 0 ? avgDuration / avgHourlyDuration : 1.0
            
            return TimeOfDayAnalysis(
                hour: hour,
                completionCount: stats.count,
                averageDuration: avgHourlyDuration,
                efficiency: min(max(efficiency, 0), 2.0) // Cap at 2x efficiency
            )
        }.sorted { $0.hour < $1.hour }
    }
    
    private static func calculateAverageDuration(tasks: [TodoTask]) -> TimeInterval {
        let durations = tasks.compactMap { task -> TimeInterval? in
            if let completionDate = task.completionDate, let startedAt = task.startedAt {
                return completionDate.timeIntervalSince(startedAt)
            }
            return task.estimatedDuration
        }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }
    
    private static func analyzeWorkPattern(tasks: [TodoTask]) -> (pattern: String, description: String, recommendation: String) {
        let calendar = Calendar.current
        var weekdayCompletions: [Int: Int] = [:]
        
        for task in tasks where task.isCompleted {
            if let date = task.completionDate {
                let weekday = calendar.component(.weekday, from: date)
                weekdayCompletions[weekday, default: 0] += 1
            }
        }
        
        let totalCompletions = weekdayCompletions.values.reduce(0, +)
        guard totalCompletions > 0 else {
            return ("No Pattern", "Not enough data", "Complete more tasks to identify patterns")
        }
        
        // Identify pattern
        let weekendCompletions = (weekdayCompletions[1, default: 0] + weekdayCompletions[7, default: 0])
        let weekdayCompletionsCount = totalCompletions - weekendCompletions
        
        if Double(weekendCompletions) / Double(totalCompletions) > 0.4 {
            return ("Weekend Warrior", "You complete most tasks on weekends", "Consider spreading tasks throughout the week for better work-life balance")
        } else if Double(weekdayCompletionsCount) / Double(totalCompletions) > 0.8 {
            return ("Weekday Focus", "You're most productive during weekdays", "Great pattern! Keep dedicated weekend time for rest")
        } else {
            return ("Balanced", "You maintain consistent productivity throughout the week", "Your balanced approach is working well")
        }
    }
    
    private static func analyzeProcrastination(tasks: [TodoTask]) -> Double {
        let delayedTasks = tasks.filter { task in
            guard let scheduledDate = task.scheduledDate,
                  let completionDate = task.completionDate else { return false }
            return completionDate > scheduledDate
        }
        
        guard !tasks.isEmpty else { return 0 }
        return Double(delayedTasks.count) / Double(tasks.count)
    }
    
    private static func calculateMomentum(tasks: [TodoTask]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        // Check last 7 days
        var dailyCompletions: [Int] = []
        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let completions = tasks.filter { task in
                guard let completionDate = task.completionDate else { return false }
                return completionDate >= dayStart && completionDate < dayEnd
            }.count
            
            dailyCompletions.append(completions)
        }
        
        // Calculate momentum based on consistency and recent activity
        let recentAvg = Double(dailyCompletions.prefix(3).reduce(0, +)) / 3.0
        let totalAvg = Double(dailyCompletions.reduce(0, +)) / 7.0
        
        guard totalAvg > 0 else { return 0 }
        return min(recentAvg / totalAvg, 1.5) / 1.5 // Normalize to 0-1
    }
    
    private static func analyzeProjectHealth(projects: [Project], tasks: [TodoTask]) -> [ProjectHealthMetric] {
        return projects.map { project in
            let projectTasks = tasks.filter { $0.projectId == project.id }
            let completedTasks = projectTasks.filter { $0.isCompleted }
            let overdueTasks = projectTasks.filter { task in
                guard let dueDate = task.dueDate, !task.isCompleted else { return false }
                return dueDate < Date()
            }
            
            let completionRate = projectTasks.isEmpty ? 0 : Double(completedTasks.count) / Double(projectTasks.count)
            
            // Calculate momentum (recent completions)
            let recentCompletions = completedTasks.filter { task in
                guard let date = task.completionDate else { return false }
                return Calendar.current.dateComponents([.day], from: date, to: Date()).day! <= 7
            }.count
            
            let momentum = min(Double(recentCompletions) / 3.0, 1.0) // Expect 3 tasks per week
            
            // Calculate health score
            var health = completionRate * 0.4 + momentum * 0.3
            if !overdueTasks.isEmpty {
                health -= Double(overdueTasks.count) * 0.1
            }
            if let deadline = project.deadline, deadline < Date() && completionRate < 1.0 {
                health -= 0.2
            }
            
            health = max(0, min(1, health))
            
            // Identify risks
            var risks: [String] = []
            if overdueTasks.count > 0 {
                risks.append("\(overdueTasks.count) overdue tasks")
            }
            if momentum < 0.3 {
                risks.append("Low recent activity")
            }
            if let deadline = project.deadline, deadline < Date() && completionRate < 1.0 {
                risks.append("Past deadline")
            }
            
            // Estimate completion
            let estimatedCompletion: Date? = nil // Would require more complex calculation
            
            return ProjectHealthMetric(
                project: project,
                health: health,
                completionRate: completionRate,
                overdueCount: overdueTasks.count,
                momentum: momentum,
                estimatedCompletion: estimatedCompletion,
                risks: risks
            )
        }
    }
    
    private static func calculateOverallProductivityScore(completionRate: Double, momentum: Double, procrastination: Double) -> Double {
        let score = (completionRate * 0.4) + (momentum * 0.4) + ((1 - procrastination) * 0.2)
        return max(0, min(1, score))
    }
    
    private static func calculateProductivityStreak(tasks: [TodoTask]) -> Int {
        let calendar = Calendar.current
        var currentDate = Date()
        var streakDays = 0
        
        while true {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let completions = tasks.filter { task in
                guard let completionDate = task.completionDate else { return false }
                return completionDate >= dayStart && completionDate < dayEnd
            }.count
            
            if completions > 0 {
                streakDays += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else if calendar.isDateInToday(currentDate) {
                // Don't break streak for today if no completions yet
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streakDays
    }
    
    private static func determineTrend(current: Double, previous: Double) -> ProductivityInsight.Trend {
        let threshold = 0.05 // 5% change threshold
        
        if abs(current - previous) < threshold {
            return .stable
        } else if current > previous {
            return .improving
        } else {
            return .declining
        }
    }
    
    private static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private static func generateSuggestions(insights: [ProductivityInsight], projectHealth: [ProjectHealthMetric], overallScore: Double) -> [String] {
        var suggestions: [String] = []
        
        // Based on overall score
        if overallScore < 0.5 {
            suggestions.append("Start with quick wins - complete 2-3 small tasks to build momentum")
        }
        
        // Based on insights
        if let completionInsight = insights.first(where: { $0.type == .completionRate }),
           completionInsight.value.contains("%"),
           let percentage = Int(completionInsight.value.replacingOccurrences(of: "%", with: "")),
           percentage < 70 {
            suggestions.append("Review and close tasks that are no longer relevant")
        }
        
        // Based on project health
        let criticalProjects = projectHealth.filter { $0.health < 0.4 }
        if !criticalProjects.isEmpty {
            suggestions.append("Focus on critical projects: \(criticalProjects.map { $0.project.name }.joined(separator: ", "))")
        }
        
        // Time-based suggestions
        if let peakTime = insights.first(where: { $0.type == .peakProductivity }) {
            suggestions.append("Block your calendar around \(peakTime.value) for focused work")
        }
        
        return suggestions
    }
}
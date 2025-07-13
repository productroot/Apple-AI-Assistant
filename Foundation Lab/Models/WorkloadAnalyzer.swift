import Foundation
import SwiftUI

struct WorkloadAnalyzer {
    struct DailyWorkload: Identifiable {
        let id = UUID()
        let date: Date
        let tasks: [TodoTask]
        let totalEstimatedDuration: TimeInterval
        let taskCount: Int
        let highPriorityCount: Int
        let hasDeadlines: Bool
        
        var workloadScore: Double {
            // Calculate a score from 0-100 based on various factors
            var score: Double = 0
            
            // Duration factor (assuming 8 hour work day)
            let hoursOfWork = totalEstimatedDuration / 3600
            let durationScore = min(hoursOfWork / 8.0 * 50, 50) // Max 50 points for duration
            score += durationScore
            
            // Task count factor
            let taskScore = min(Double(taskCount) * 3, 30) // Max 30 points for task count
            score += taskScore
            
            // Priority factor
            let priorityScore = Double(highPriorityCount) * 5 // 5 points per high priority task
            score += priorityScore
            
            // Deadline pressure
            if hasDeadlines {
                score += 10
            }
            
            return min(score, 100)
        }
        
        var workloadLevel: WorkloadLevel {
            switch workloadScore {
            case 0..<30: return .light
            case 30..<60: return .moderate
            case 60..<80: return .heavy
            default: return .overloaded
            }
        }
    }
    
    enum WorkloadLevel {
        case light
        case moderate
        case heavy
        case overloaded
        
        var color: Color {
            switch self {
            case .light: return .green
            case .moderate: return .yellow
            case .heavy: return .orange
            case .overloaded: return .red
            }
        }
        
        var description: String {
            switch self {
            case .light: return "Light workload"
            case .moderate: return "Moderate workload"
            case .heavy: return "Heavy workload"
            case .overloaded: return "Overloaded"
            }
        }
        
        var emoji: String {
            switch self {
            case .light: return "😌"
            case .moderate: return "💪"
            case .heavy: return "😤"
            case .overloaded: return "🔥"
            }
        }
    }
    
    struct WorkloadInsight {
        let overloadedDays: [DailyWorkload]
        let lightDays: [DailyWorkload]
        let suggestedMoves: [TaskMove]
        let averageWorkloadScore: Double
        let peakDay: DailyWorkload?
    }
    
    struct TaskMove {
        let task: TodoTask
        let fromDate: Date
        let toDate: Date
        let reason: String
    }
    
    static func analyzeWorkload(tasks: [TodoTask], dateRange: ClosedRange<Date>) -> [DailyWorkload] {
        let calendar = Calendar.current
        var dailyWorkloads: [DailyWorkload] = []
        
        // Group tasks by scheduled date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Create a dictionary of tasks by date
        var tasksByDate: [String: [TodoTask]] = [:]
        
        for task in tasks where !task.isCompleted {
            if let scheduledDate = task.scheduledDate {
                let dateKey = dateFormatter.string(from: scheduledDate)
                tasksByDate[dateKey, default: []].append(task)
            }
        }
        
        // Analyze each day in the range
        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let dateKey = dateFormatter.string(from: currentDate)
            let dayTasks = tasksByDate[dateKey] ?? []
            
            let totalDuration = dayTasks.reduce(0) { $0 + ($1.estimatedDuration ?? 1800) } // Default 30 min
            let highPriorityCount = dayTasks.filter { $0.priority == .high || $0.priority == .asap }.count
            let hasDeadlines = dayTasks.contains { $0.dueDate != nil }
            
            let workload = DailyWorkload(
                date: currentDate,
                tasks: dayTasks,
                totalEstimatedDuration: totalDuration,
                taskCount: dayTasks.count,
                highPriorityCount: highPriorityCount,
                hasDeadlines: hasDeadlines
            )
            
            dailyWorkloads.append(workload)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        
        return dailyWorkloads
    }
    
    static func generateInsights(from workloads: [DailyWorkload]) -> WorkloadInsight {
        let overloadedDays = workloads.filter { $0.workloadLevel == .overloaded }
        let lightDays = workloads.filter { $0.workloadLevel == .light }
        
        let totalScore = workloads.reduce(0.0) { $0 + $1.workloadScore }
        let averageScore = workloads.isEmpty ? 0 : totalScore / Double(workloads.count)
        
        let peakDay = workloads.max { $0.workloadScore < $1.workloadScore }
        
        // Generate task move suggestions
        var suggestedMoves: [TaskMove] = []
        
        for overloadedDay in overloadedDays {
            // Find tasks that could be moved
            let movableTasks = overloadedDay.tasks.filter { 
                $0.dueDate == nil || $0.dueDate! > overloadedDay.date 
            }
            
            for task in movableTasks.prefix(2) { // Suggest moving up to 2 tasks
                // Find a light day after the current day but before the due date
                let potentialDays = lightDays.filter { lightDay in
                    lightDay.date > overloadedDay.date &&
                    (task.dueDate == nil || lightDay.date <= task.dueDate!)
                }
                
                if let targetDay = potentialDays.first {
                    suggestedMoves.append(TaskMove(
                        task: task,
                        fromDate: overloadedDay.date,
                        toDate: targetDay.date,
                        reason: "Balance workload from overloaded day"
                    ))
                }
            }
        }
        
        return WorkloadInsight(
            overloadedDays: overloadedDays,
            lightDays: lightDays,
            suggestedMoves: suggestedMoves,
            averageWorkloadScore: averageScore,
            peakDay: peakDay
        )
    }
    
    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
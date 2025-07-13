import Foundation

struct RecurrencePatternDetector {
    struct PatternMatch: Identifiable {
        let id = UUID()
        let taskTitle: String
        let occurrences: [Date]
        let suggestedRule: RecurrenceRule
        let confidence: PatternConfidence
        let reason: String
        
        var averageInterval: TimeInterval? {
            guard occurrences.count > 1 else { return nil }
            
            let sortedDates = occurrences.sorted()
            var intervals: [TimeInterval] = []
            
            for i in 1..<sortedDates.count {
                intervals.append(sortedDates[i].timeIntervalSince(sortedDates[i-1]))
            }
            
            return intervals.reduce(0, +) / Double(intervals.count)
        }
    }
    
    enum PatternConfidence {
        case high
        case medium
        case low
        
        var description: String {
            switch self {
            case .high: return "High confidence"
            case .medium: return "Medium confidence"
            case .low: return "Low confidence"
            }
        }
        
        var emoji: String {
            switch self {
            case .high: return "🟢"
            case .medium: return "🟡"
            case .low: return "🟠"
            }
        }
    }
    
    struct TaskOccurrence {
        let title: String
        let completedAt: Date
        let projectId: UUID?
        let tags: [String]
    }
    
    static func detectPatterns(from completedTasks: [TodoTask]) -> [PatternMatch] {
        // Convert completed tasks to occurrences
        let occurrences = completedTasks
            .filter { $0.isCompleted && $0.completionDate != nil }
            .map { task in
                TaskOccurrence(
                    title: task.title,
                    completedAt: task.completionDate!,
                    projectId: task.projectId,
                    tags: task.tags
                )
            }
        
        // Group tasks by similar titles
        let groupedTasks = groupTasksBySimilarity(occurrences)
        
        // Analyze each group for patterns
        var patterns: [PatternMatch] = []
        
        for (_, group) in groupedTasks {
            if let pattern = analyzeGroup(group) {
                patterns.append(pattern)
            }
        }
        
        return patterns.sorted { $0.confidence.hashValue > $1.confidence.hashValue }
    }
    
    private static func groupTasksBySimilarity(_ occurrences: [TaskOccurrence]) -> [String: [TaskOccurrence]] {
        var groups: [String: [TaskOccurrence]] = [:]
        
        for occurrence in occurrences {
            // Normalize title for grouping
            let normalizedTitle = normalizeTitle(occurrence.title)
            
            // Find existing group or create new one
            var foundGroup = false
            for (key, _) in groups {
                if areTitlesSimilar(normalizedTitle, key) {
                    groups[key]?.append(occurrence)
                    foundGroup = true
                    break
                }
            }
            
            if !foundGroup {
                groups[normalizedTitle] = [occurrence]
            }
        }
        
        // Filter out groups with less than 3 occurrences
        return groups.filter { $0.value.count >= 3 }
    }
    
    private static func normalizeTitle(_ title: String) -> String {
        // Remove common variations
        let lowercased = title.lowercased()
        let withoutNumbers = lowercased.replacingOccurrences(
            of: #"\d+"#,
            with: "",
            options: .regularExpression
        )
        let trimmed = withoutNumbers.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common words that might vary
        let commonWords = ["the", "a", "an", "on", "at", "in", "for", "with", "and", "or"]
        let words = trimmed.split(separator: " ")
        let filtered = words.filter { !commonWords.contains(String($0)) }
        
        return filtered.joined(separator: " ")
    }
    
    private static func areTitlesSimilar(_ title1: String, _ title2: String) -> Bool {
        // Calculate similarity using Levenshtein distance
        let distance = levenshteinDistance(title1, title2)
        let maxLength = max(title1.count, title2.count)
        let similarity = 1.0 - (Double(distance) / Double(maxLength))
        
        return similarity > 0.7 // 70% similarity threshold
    }
    
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)
        
        for i in 0...s1Array.count {
            matrix[i][0] = i
        }
        
        for j in 0...s2Array.count {
            matrix[0][j] = j
        }
        
        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                if s1Array[i-1] == s2Array[j-1] {
                    matrix[i][j] = matrix[i-1][j-1]
                } else {
                    matrix[i][j] = min(
                        matrix[i-1][j] + 1,
                        matrix[i][j-1] + 1,
                        matrix[i-1][j-1] + 1
                    )
                }
            }
        }
        
        return matrix[s1Array.count][s2Array.count]
    }
    
    private static func analyzeGroup(_ group: [TaskOccurrence]) -> PatternMatch? {
        guard group.count >= 3 else { return nil }
        
        let sortedOccurrences = group.sorted { $0.completedAt < $1.completedAt }
        let dates = sortedOccurrences.map { $0.completedAt }
        
        // Calculate intervals between occurrences
        var intervals: [TimeInterval] = []
        for i in 1..<dates.count {
            intervals.append(dates[i].timeIntervalSince(dates[i-1]))
        }
        
        // Analyze intervals to determine pattern
        let averageInterval = intervals.reduce(0, +) / Double(intervals.count)
        let stdDeviation = calculateStandardDeviation(intervals)
        
        // Determine recurrence rule based on average interval
        let (rule, confidence, reason) = determineRecurrenceRule(
            averageInterval: averageInterval,
            standardDeviation: stdDeviation,
            occurrences: sortedOccurrences
        )
        
        return PatternMatch(
            taskTitle: group.first?.title ?? "",
            occurrences: dates,
            suggestedRule: rule,
            confidence: confidence,
            reason: reason
        )
    }
    
    private static func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDifferences = values.map { pow($0 - mean, 2) }
        let variance = squaredDifferences.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
    
    private static func determineRecurrenceRule(
        averageInterval: TimeInterval,
        standardDeviation: Double,
        occurrences: [TaskOccurrence]
    ) -> (RecurrenceRule, PatternConfidence, String) {
        let dayInSeconds: TimeInterval = 86400
        
        let intervalInDays = averageInterval / dayInSeconds
        let deviationInDays = standardDeviation / dayInSeconds
        
        // Calculate confidence based on consistency
        let coefficientOfVariation = standardDeviation / averageInterval
        let confidence: PatternConfidence
        if coefficientOfVariation < 0.2 {
            confidence = .high
        } else if coefficientOfVariation < 0.4 {
            confidence = .medium
        } else {
            confidence = .low
        }
        
        // Determine rule based on interval
        if intervalInDays < 1.5 && deviationInDays < 0.5 {
            return (.daily, confidence, "Task completed approximately daily")
        } else if abs(intervalInDays - 7) < 1.5 && deviationInDays < 2 {
            // Check if it's on specific weekdays
            if let weekdayPattern = detectWeekdayPattern(occurrences) {
                return (weekdayPattern, confidence, "Task completed on specific weekdays")
            }
            return (.weekly, confidence, "Task completed approximately weekly")
        } else if abs(intervalInDays - 14) < 2 && deviationInDays < 3 {
            return (.biweekly, confidence, "Task completed approximately every two weeks")
        } else if abs(intervalInDays - 30) < 5 && deviationInDays < 7 {
            return (.monthly, confidence, "Task completed approximately monthly")
        } else if abs(intervalInDays - 365) < 30 {
            return (.yearly, confidence, "Task completed approximately yearly")
        } else {
            return (.custom, .low, "No clear pattern detected")
        }
    }
    
    private static func detectWeekdayPattern(_ occurrences: [TaskOccurrence]) -> RecurrenceRule? {
        let calendar = Calendar.current
        let weekdays = occurrences.map { calendar.component(.weekday, from: $0.completedAt) }
        
        // Check if all on weekdays (Monday-Friday)
        if weekdays.allSatisfy({ $0 >= 2 && $0 <= 6 }) {
            return .weekdays
        }
        
        // Check if all on weekends
        if weekdays.allSatisfy({ $0 == 1 || $0 == 7 }) {
            return .weekends
        }
        
        return nil
    }
}
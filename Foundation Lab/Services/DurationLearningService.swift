//
//  DurationLearningService.swift
//  FoundationLab
//
//  Created by Assistant on 7/12/25.
//

import Foundation
import SwiftUI

/// Service for tracking and learning from task duration estimates vs actual completion times
@Observable
final class DurationLearningService {
    static let shared = DurationLearningService()
    
    // MARK: - Properties
    internal var durationHistory: [DurationRecord] = []
    internal let maxHistorySize = 1000
    private let similarityThreshold = 0.7
    
    // MARK: - Persistence Keys
    private let historyKey = "com.foundationlab.durationHistory"
    
    // MARK: - Initialization
    private init() {
        loadHistory()
    }
    
    // MARK: - Public Methods
    
    /// Records an AI duration estimate for a task
    func recordEstimate(
        taskId: UUID,
        taskTitle: String,
        taskNotes: String,
        checklistCount: Int,
        aiEstimateMinutes: Int,
        projectName: String? = nil
    ) {
        print("📊 Recording AI estimate for task: \(taskTitle)")
        
        let record = DurationRecord(
            id: UUID(),
            taskId: taskId,
            taskTitle: taskTitle,
            taskNotes: taskNotes,
            checklistCount: checklistCount,
            projectName: projectName,
            aiEstimateMinutes: aiEstimateMinutes,
            userOverrideMinutes: nil,
            actualDurationMinutes: nil,
            createdAt: Date(),
            completedAt: nil
        )
        
        addRecord(record)
    }
    
    /// Records when a user manually overrides the AI estimate
    func recordUserOverride(taskId: UUID, userMinutes: Int) {
        print("✏️ Recording user override for task ID: \(taskId) - \(userMinutes) minutes")
        
        if let index = durationHistory.firstIndex(where: { $0.taskId == taskId }) {
            durationHistory[index].userOverrideMinutes = userMinutes
            saveHistory()
        }
    }
    
    /// Records the actual duration when a task is completed
    func recordCompletion(taskId: UUID, actualMinutes: Int) {
        print("✅ Recording task completion for ID: \(taskId) - \(actualMinutes) minutes")
        
        if let index = durationHistory.firstIndex(where: { $0.taskId == taskId }) {
            durationHistory[index].actualDurationMinutes = actualMinutes
            durationHistory[index].completedAt = Date()
            saveHistory()
        }
    }
    
    /// Finds similar completed tasks to help with estimation
    func findSimilarTasks(
        to taskTitle: String,
        taskNotes: String,
        checklistCount: Int,
        limit: Int = 5
    ) -> [(title: String, estimatedMinutes: Int, actualMinutes: Int)] {
        print("🔍 Finding similar tasks to: \(taskTitle)")
        
        // Filter completed tasks with actual durations
        let completedTasks = durationHistory.filter { $0.actualDurationMinutes != nil }
        
        // Calculate similarity scores
        let scoredTasks = completedTasks.map { record -> (record: DurationRecord, score: Double) in
            let titleSimilarity = calculateSimilarity(taskTitle, record.taskTitle)
            let notesSimilarity = calculateSimilarity(taskNotes, record.taskNotes)
            let checklistSimilarity = 1.0 - (abs(Double(checklistCount - record.checklistCount)) / 10.0)
            
            // Weighted average (title is most important)
            let score = (titleSimilarity * 0.5) + (notesSimilarity * 0.3) + (checklistSimilarity * 0.2)
            return (record, score)
        }
        
        // Sort by similarity and take top matches
        let topMatches = scoredTasks
            .filter { $0.score >= similarityThreshold }
            .sorted { $0.score > $1.score }
            .prefix(limit)
        
        // Convert to result format
        let results = topMatches.compactMap { match -> (title: String, estimatedMinutes: Int, actualMinutes: Int)? in
            guard let actualMinutes = match.record.actualDurationMinutes else { return nil }
            
            // Use user override if available, otherwise AI estimate
            let estimatedMinutes = match.record.userOverrideMinutes ?? match.record.aiEstimateMinutes
            
            return (
                title: match.record.taskTitle,
                estimatedMinutes: estimatedMinutes,
                actualMinutes: actualMinutes
            )
        }
        
        print("✅ Found \(results.count) similar tasks")
        return Array(results)
    }
    
    /// Gets accuracy statistics for AI estimations
    func getAccuracyStats() -> AccuracyStats {
        let completedWithEstimates = durationHistory.filter {
            $0.actualDurationMinutes != nil
        }
        
        guard !completedWithEstimates.isEmpty else {
            return AccuracyStats(
                totalTasks: 0,
                averageAccuracy: 0,
                overestimatedCount: 0,
                underestimatedCount: 0,
                accurateCount: 0
            )
        }
        
        var totalAccuracy: Double = 0
        var overestimated = 0
        var underestimated = 0
        var accurate = 0
        
        for record in completedWithEstimates {
            guard let actual = record.actualDurationMinutes else { continue }
            
            let estimated = record.userOverrideMinutes ?? record.aiEstimateMinutes
            let accuracy = 1.0 - abs(Double(estimated - actual)) / Double(actual)
            totalAccuracy += max(0, accuracy)
            
            let difference = estimated - actual
            if abs(difference) <= 5 { // Within 5 minutes is considered accurate
                accurate += 1
            } else if difference > 0 {
                overestimated += 1
            } else {
                underestimated += 1
            }
        }
        
        return AccuracyStats(
            totalTasks: completedWithEstimates.count,
            averageAccuracy: totalAccuracy / Double(completedWithEstimates.count),
            overestimatedCount: overestimated,
            underestimatedCount: underestimated,
            accurateCount: accurate
        )
    }
    
    // MARK: - Private Methods
    
    private func addRecord(_ record: DurationRecord) {
        durationHistory.insert(record, at: 0)
        
        // Maintain max history size
        if durationHistory.count > maxHistorySize {
            durationHistory = Array(durationHistory.prefix(maxHistorySize))
        }
        
        saveHistory()
    }
    
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(str2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        guard !words1.isEmpty && !words2.isEmpty else { return 0 }
        
        let intersection = words1.intersection(words2).count
        let union = words1.union(words2).count
        
        return Double(intersection) / Double(union)
    }
    
    // MARK: - Persistence
    
    internal func saveHistory() {
        do {
            let data = try JSONEncoder().encode(durationHistory)
            UserDefaults.standard.set(data, forKey: historyKey)
            print("💾 Saved \(durationHistory.count) duration records")
        } catch {
            print("❌ Failed to save duration history: \(error)")
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else {
            print("📂 No duration history found")
            return
        }
        
        do {
            durationHistory = try JSONDecoder().decode([DurationRecord].self, from: data)
            print("📂 Loaded \(durationHistory.count) duration records")
        } catch {
            print("❌ Failed to load duration history: \(error)")
        }
    }
}

// MARK: - Supporting Types

struct DurationRecord: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let taskTitle: String
    let taskNotes: String
    let checklistCount: Int
    let projectName: String?
    let aiEstimateMinutes: Int
    var userOverrideMinutes: Int?
    var actualDurationMinutes: Int?
    let createdAt: Date
    var completedAt: Date?
}

struct AccuracyStats {
    let totalTasks: Int
    let averageAccuracy: Double
    let overestimatedCount: Int
    let underestimatedCount: Int
    let accurateCount: Int
    
    var accuracyPercentage: Int {
        Int(averageAccuracy * 100)
    }
}
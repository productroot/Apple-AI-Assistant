//
//  AILearningData.swift
//  FoundationLab
//
//  Created by Assistant on 7/13/25.
//

import Foundation

/// Unified model for all AI learning data that needs to be synced to iCloud
struct AILearningData: Codable {
    // Duration Learning Data
    let durationHistory: [DurationRecord]
    
    // Optimization Feedback Data
    let optimizationFeedback: [OptimizationFeedback]
    let userPreferences: [String]
    
    // Metadata
    let lastUpdated: Date
    let version: Int
    
    init(
        durationHistory: [DurationRecord] = [],
        optimizationFeedback: [OptimizationFeedback] = [],
        userPreferences: [String] = [],
        lastUpdated: Date = Date(),
        version: Int = 1
    ) {
        self.durationHistory = durationHistory
        self.optimizationFeedback = optimizationFeedback
        self.userPreferences = userPreferences
        self.lastUpdated = lastUpdated
        self.version = version
    }
}

/// Extension to make services iCloud-compatible
extension DurationLearningService {
    /// Exports all duration learning data for iCloud sync
    func exportLearningData() -> [DurationRecord] {
        return durationHistory
    }
    
    /// Imports duration learning data from iCloud
    func importLearningData(_ records: [DurationRecord]) {
        print("📥 Importing \(records.count) duration records from iCloud")
        
        // Merge with existing data, avoiding duplicates
        var mergedHistory = durationHistory
        let existingIds = Set(durationHistory.map { $0.id })
        
        for record in records {
            if !existingIds.contains(record.id) {
                mergedHistory.append(record)
            }
        }
        
        // Sort by creation date and maintain max size
        mergedHistory.sort { $0.createdAt > $1.createdAt }
        if mergedHistory.count > maxHistorySize {
            mergedHistory = Array(mergedHistory.prefix(maxHistorySize))
        }
        
        durationHistory = mergedHistory
        saveHistory()
        
        print("✅ Duration learning data imported successfully")
    }
}

extension OptimizationFeedbackService {
    /// Exports all optimization feedback data for iCloud sync
    func exportFeedbackData() -> (feedback: [OptimizationFeedback], preferences: [String]) {
        return (feedbackHistory, userPreferences)
    }
    
    /// Imports optimization feedback data from iCloud
    func importFeedbackData(feedback: [OptimizationFeedback], preferences: [String]) {
        print("📥 Importing \(feedback.count) feedback records and \(preferences.count) preferences from iCloud")
        
        // Merge feedback history
        var mergedFeedback = feedbackHistory
        let existingIds = Set(feedbackHistory.map { $0.id })
        
        for record in feedback {
            if !existingIds.contains(record.id) {
                mergedFeedback.append(record)
            }
        }
        
        // Sort by timestamp and maintain max size
        mergedFeedback.sort { $0.timestamp > $1.timestamp }
        if mergedFeedback.count > maxHistorySize {
            mergedFeedback = Array(mergedFeedback.prefix(maxHistorySize))
        }
        
        feedbackHistory = mergedFeedback
        
        // Merge preferences, avoiding duplicates
        var mergedPreferences = userPreferences
        for pref in preferences {
            if !mergedPreferences.contains(pref) {
                mergedPreferences.append(pref)
            }
        }
        
        // Maintain max preferences
        if mergedPreferences.count > maxPreferences {
            mergedPreferences = Array(mergedPreferences.prefix(maxPreferences))
        }
        
        userPreferences = mergedPreferences
        saveData()
        
        print("✅ Optimization feedback data imported successfully")
    }
}

/// Manager for AI learning data sync
@Observable
final class AILearningDataManager {
    static let shared = AILearningDataManager()
    
    private init() {}
    
    /// Collects all AI learning data for export
    func collectLearningData() -> AILearningData {
        let durationHistory = DurationLearningService.shared.exportLearningData()
        let (feedbackHistory, userPreferences) = OptimizationFeedbackService.shared.exportFeedbackData()
        
        return AILearningData(
            durationHistory: durationHistory,
            optimizationFeedback: feedbackHistory,
            userPreferences: userPreferences,
            lastUpdated: Date(),
            version: 1
        )
    }
    
    /// Distributes imported AI learning data to respective services
    func distributeLearningData(_ data: AILearningData) {
        DurationLearningService.shared.importLearningData(data.durationHistory)
        OptimizationFeedbackService.shared.importFeedbackData(
            feedback: data.optimizationFeedback,
            preferences: data.userPreferences
        )
        
        print("✅ AI learning data distributed to all services")
    }
}
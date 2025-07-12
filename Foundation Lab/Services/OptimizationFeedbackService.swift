//
//  OptimizationFeedbackService.swift
//  FoundationLab
//
//  Created by Assistant on 7/12/25.
//

import Foundation
import SwiftUI

/// Service for tracking user feedback on AI task optimization suggestions
@Observable
final class OptimizationFeedbackService {
    static let shared = OptimizationFeedbackService()
    
    // MARK: - Properties
    private var feedbackHistory: [OptimizationFeedback] = []
    private var userPreferences: [String] = []
    private let maxHistorySize = 500
    private let maxPreferences = 20
    
    // MARK: - Persistence Keys
    private let historyKey = "com.foundationlab.optimizationHistory"
    private let preferencesKey = "com.foundationlab.optimizationPreferences"
    
    // MARK: - Initialization
    private init() {
        loadData()
    }
    
    // MARK: - Public Methods
    
    /// Records user acceptance of an AI suggestion
    func recordAcceptance(
        taskId: UUID,
        originalPriority: String,
        suggestedPriority: String,
        suggestedAction: String,
        reasoning: String
    ) {
        print("✅ Recording acceptance for task \(taskId)")
        
        let feedback = OptimizationFeedback(
            id: UUID(),
            taskId: taskId,
            originalPriority: originalPriority,
            suggestedPriority: suggestedPriority,
            userAcceptedPriority: suggestedPriority,
            suggestedAction: suggestedAction,
            userAcceptedAction: suggestedAction,
            reasoning: reasoning,
            wasAccepted: true,
            timestamp: Date()
        )
        
        addFeedback(feedback)
        extractPreference(from: feedback)
    }
    
    /// Records user rejection and modification of an AI suggestion
    func recordRejection(
        taskId: UUID,
        originalPriority: String,
        suggestedPriority: String,
        userPriority: String,
        suggestedAction: String,
        userAction: String,
        reasoning: String
    ) {
        print("❌ Recording rejection for task \(taskId)")
        
        let feedback = OptimizationFeedback(
            id: UUID(),
            taskId: taskId,
            originalPriority: originalPriority,
            suggestedPriority: suggestedPriority,
            userAcceptedPriority: userPriority,
            suggestedAction: suggestedAction,
            userAcceptedAction: userAction,
            reasoning: reasoning,
            wasAccepted: false,
            timestamp: Date()
        )
        
        addFeedback(feedback)
        extractPreference(from: feedback)
    }
    
    /// Gets user preferences learned from feedback
    func getUserPreferences() -> [String] {
        return userPreferences
    }
    
    /// Analyzes feedback patterns to identify user preferences
    func analyzeFeedbackPatterns() -> FeedbackAnalysis {
        let recentFeedback = feedbackHistory.suffix(100) // Analyze last 100 items
        
        guard !recentFeedback.isEmpty else {
            return FeedbackAnalysis(
                acceptanceRate: 0,
                commonRejectionReasons: [],
                preferredActions: [],
                priorityAdjustmentPatterns: []
            )
        }
        
        // Calculate acceptance rate
        let acceptanceRate = Double(recentFeedback.filter { $0.wasAccepted }.count) / Double(recentFeedback.count)
        
        // Analyze rejection patterns
        let rejections = recentFeedback.filter { !$0.wasAccepted }
        
        // Common rejection patterns
        var rejectionPatterns: [String: Int] = [:]
        for rejection in rejections {
            let pattern = "\(rejection.suggestedAction) → \(rejection.userAcceptedAction)"
            rejectionPatterns[pattern, default: 0] += 1
        }
        
        let commonRejectionReasons = rejectionPatterns
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { "User prefers '\($0.key.split(separator: " → ").last ?? "")' over '\($0.key.split(separator: " → ").first ?? "")'" }
        
        // Preferred actions
        let allActions = recentFeedback.map { $0.userAcceptedAction }
        let actionCounts = Dictionary(grouping: allActions, by: { $0 }).mapValues { $0.count }
        let preferredActions = actionCounts
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
        
        // Priority adjustment patterns
        var priorityPatterns: [String] = []
        for feedback in rejections {
            if feedback.suggestedPriority != feedback.userAcceptedPriority {
                priorityPatterns.append("User changed \(feedback.suggestedPriority) to \(feedback.userAcceptedPriority)")
            }
        }
        
        return FeedbackAnalysis(
            acceptanceRate: acceptanceRate,
            commonRejectionReasons: commonRejectionReasons,
            preferredActions: preferredActions,
            priorityAdjustmentPatterns: Array(Set(priorityPatterns).prefix(5))
        )
    }
    
    // MARK: - Private Methods
    
    private func addFeedback(_ feedback: OptimizationFeedback) {
        feedbackHistory.insert(feedback, at: 0)
        
        // Maintain max history size
        if feedbackHistory.count > maxHistorySize {
            feedbackHistory = Array(feedbackHistory.prefix(maxHistorySize))
        }
        
        saveData()
    }
    
    private func extractPreference(from feedback: OptimizationFeedback) {
        if !feedback.wasAccepted {
            // Learn from rejections
            let preference = "User prefers \(feedback.userAcceptedAction) over \(feedback.suggestedAction) for similar tasks"
            
            // Avoid duplicates
            if !userPreferences.contains(preference) {
                userPreferences.insert(preference, at: 0)
                
                // Maintain max preferences
                if userPreferences.count > maxPreferences {
                    userPreferences = Array(userPreferences.prefix(maxPreferences))
                }
            }
        }
        
        saveData()
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        do {
            let encoder = JSONEncoder()
            
            let historyData = try encoder.encode(feedbackHistory)
            UserDefaults.standard.set(historyData, forKey: historyKey)
            
            let preferencesData = try encoder.encode(userPreferences)
            UserDefaults.standard.set(preferencesData, forKey: preferencesKey)
            
            print("💾 Saved optimization feedback data")
        } catch {
            print("❌ Failed to save optimization feedback: \(error)")
        }
    }
    
    private func loadData() {
        let decoder = JSONDecoder()
        
        if let historyData = UserDefaults.standard.data(forKey: historyKey),
           let history = try? decoder.decode([OptimizationFeedback].self, from: historyData) {
            feedbackHistory = history
            print("📂 Loaded \(feedbackHistory.count) feedback records")
        }
        
        if let preferencesData = UserDefaults.standard.data(forKey: preferencesKey),
           let preferences = try? decoder.decode([String].self, from: preferencesData) {
            userPreferences = preferences
            print("📂 Loaded \(userPreferences.count) user preferences")
        }
    }
}

// MARK: - Supporting Types

struct OptimizationFeedback: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let originalPriority: String
    let suggestedPriority: String
    let userAcceptedPriority: String
    let suggestedAction: String
    let userAcceptedAction: String
    let reasoning: String
    let wasAccepted: Bool
    let timestamp: Date
}

struct FeedbackAnalysis {
    let acceptanceRate: Double
    let commonRejectionReasons: [String]
    let preferredActions: [String]
    let priorityAdjustmentPatterns: [String]
    
    var acceptancePercentage: Int {
        Int(acceptanceRate * 100)
    }
}
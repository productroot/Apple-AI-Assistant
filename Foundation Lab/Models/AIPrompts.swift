//
//  AIPrompts.swift
//  FoundationLab
//
//  Created by Assistant on 7/11/25.
//

import Foundation

/// Centralized AI prompt management for consistent prompt engineering across the app
enum AIPrompts {
    
    // MARK: - Project Description Generation
    
    /// Generates a prompt for creating comprehensive project descriptions
    /// - Parameters:
    ///   - projectName: The name of the project
    ///   - areaName: Optional area name the project belongs to
    ///   - existingNotes: Optional existing notes to use as context
    ///   - deadline: Optional project deadline
    /// - Returns: A formatted prompt string
    static func projectDescription(
        projectName: String,
        areaName: String? = nil,
        existingNotes: String? = nil,
        deadline: Date? = nil
    ) -> String {
        var prompt = "Generate a comprehensive description for a project named '\(projectName)'."
        
        // Add area context if available
        if let areaName = areaName {
            prompt += " This project belongs to the '\(areaName)' area."
        }
        
        // Add existing notes as context if available
        if let existingNotes = existingNotes, !existingNotes.isEmpty {
            prompt += " Current notes: \(existingNotes)"
        }
        
        // Add deadline context if available
        if let deadline = deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            prompt += " The project has a deadline of \(formatter.string(from: deadline))."
        }
        
        prompt += " Provide a detailed and inspiring description that explains the project's purpose, goals, and value."
        
        return prompt
    }
    
    // MARK: - Future Prompts
    // Add more prompt generation methods here as new AI features are added
    // Example:
    // static func taskPrioritization(tasks: [TodoTask]) -> String { ... }
    // static func areaRecommendation(projectName: String) -> String { ... }
}
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
    
    // MARK: - Task Checklist Generation
    
    /// Generates a prompt for creating task checklist items
    /// - Parameters:
    ///   - taskTitle: The title of the task
    ///   - taskNotes: Optional task description/notes
    ///   - projectName: Optional project name the task belongs to
    ///   - areaName: Optional area name from the project
    /// - Returns: A formatted prompt string
    static func taskChecklist(
        taskTitle: String,
        taskNotes: String? = nil,
        projectName: String? = nil,
        areaName: String? = nil
    ) -> String {
        var prompt = "Generate a comprehensive checklist for the task: '\(taskTitle)'."
        
        // Add project context if available
        if let projectName = projectName {
            prompt += " This task is part of the '\(projectName)' project."
        }
        
        // Add area context if available
        if let areaName = areaName {
            prompt += " The project belongs to the '\(areaName)' area."
        }
        
        // Add task notes as context if available
        if let taskNotes = taskNotes, !taskNotes.isEmpty {
            prompt += " Task description: \(taskNotes)"
        }
        
        prompt += " Create specific, actionable checklist items that break down this task into manageable steps. Each item should be clear and achievable. Consider the context and provide items that are relevant to the task's domain."
        
        return prompt
    }
    
    // MARK: - Future Prompts
    // Add more prompt generation methods here as new AI features are added
}
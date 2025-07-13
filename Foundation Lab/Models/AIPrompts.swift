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
    
    // MARK: - Task Duration Estimation
    
    /// Generates a prompt for estimating task duration
    /// - Parameters:
    ///   - taskTitle: The title of the task
    ///   - taskNotes: Optional task description/notes
    ///   - checklistItems: Array of checklist items for the task
    ///   - projectName: Optional project name the task belongs to
    ///   - similarTasksHistory: Optional array of similar completed tasks with their actual durations
    /// - Returns: A formatted prompt string
    static func taskDurationEstimate(
        taskTitle: String,
        taskNotes: String? = nil,
        checklistItems: [String] = [],
        projectName: String? = nil,
        similarTasksHistory: [(title: String, estimatedMinutes: Int, actualMinutes: Int)]? = nil
    ) -> String {
        var prompt = "Estimate the duration in minutes for completing this task: '\(taskTitle)'."
        
        // Add task notes as context if available
        if let taskNotes = taskNotes, !taskNotes.isEmpty {
            prompt += " Task description: \(taskNotes)"
        }
        
        // Add checklist context if available
        if !checklistItems.isEmpty {
            prompt += " The task includes \(checklistItems.count) checklist items: \(checklistItems.joined(separator: ", "))."
        }
        
        // Add project context if available
        if let projectName = projectName {
            prompt += " This task is part of the '\(projectName)' project."
        }
        
        // Add historical data for learning if available
        if let history = similarTasksHistory, !history.isEmpty {
            prompt += " Based on similar completed tasks:"
            for task in history.prefix(5) { // Limit to 5 most relevant examples
                let accuracy = Double(task.actualMinutes) / Double(task.estimatedMinutes)
                prompt += " - '\(task.title)' was estimated at \(task.estimatedMinutes) minutes but actually took \(task.actualMinutes) minutes (accuracy: \(Int(accuracy * 100))%)."
            }
            prompt += " Consider these patterns when making your estimate."
        }
        
        prompt += " Provide a realistic estimate in minutes as a single number. Consider the complexity, the number of subtasks, and any historical patterns. Be conservative rather than optimistic."
        
        return prompt
    }
    
    // MARK: - Task Optimization
    
    /// Generates a prompt for AI-powered task optimization and planning
    /// - Parameters:
    ///   - tasks: Array of all tasks with their properties
    ///   - projects: Array of all projects
    ///   - areas: Array of all areas
    ///   - currentDate: Current date for time-based analysis
    ///   - userPreferences: Optional user preferences from past feedback
    /// - Returns: A formatted prompt string
    static func taskOptimization(
        tasks: [(id: String, title: String, notes: String, priority: String, scheduledDate: Date?, dueDate: Date?, estimatedDuration: Int?, projectId: String?, areaId: String?, tags: [String], isCompleted: Bool, recurrenceRule: String?)],
        projects: [(id: String, name: String, areaId: String?, deadline: Date?)],
        areas: [(id: String, name: String)],
        currentDate: Date,
        userPreferences: [String]? = nil
    ) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        
        var prompt = "Analyze and optimize the following task list for maximum productivity. Current date and time: \(formatter.string(from: currentDate)).\n\n"
        
        // Add areas context
        prompt += "AREAS (\(areas.count)):\n"
        for area in areas {
            prompt += "- \(area.name) (ID: \(area.id))\n"
        }
        
        // Add projects context
        prompt += "\nPROJECTS (\(projects.count)):\n"
        for project in projects {
            let areaName = areas.first { $0.id == project.areaId }?.name ?? "No Area"
            var projectInfo = "- \(project.name) [Area: \(areaName)]"
            if let deadline = project.deadline {
                projectInfo += " [Deadline: \(formatter.string(from: deadline))]"
            }
            projectInfo += " (ID: \(project.id))"
            prompt += projectInfo + "\n"
        }
        
        // Add tasks context
        prompt += "\nTASKS (\(tasks.count) active):\n"
        for task in tasks.filter({ !$0.isCompleted }) {
            var taskInfo = "- \(task.title)"
            
            if !task.notes.isEmpty {
                taskInfo += " | Notes: \(task.notes)"
            }
            
            taskInfo += " | Priority: \(task.priority)"
            
            if let projectId = task.projectId,
               let project = projects.first(where: { $0.id == projectId }) {
                taskInfo += " | Project: \(project.name)"
            }
            
            if let scheduledDate = task.scheduledDate {
                taskInfo += " | Scheduled: \(formatter.string(from: scheduledDate))"
            }
            
            if let dueDate = task.dueDate {
                taskInfo += " | Due: \(formatter.string(from: dueDate))"
            }
            
            if let duration = task.estimatedDuration {
                taskInfo += " | Duration: \(duration) min"
            }
            
            if let recurrence = task.recurrenceRule {
                taskInfo += " | Recurring: \(recurrence)"
            }
            
            if !task.tags.isEmpty {
                taskInfo += " | Tags: \(task.tags.joined(separator: ", "))"
            }
            
            taskInfo += " (ID: \(task.id))"
            prompt += taskInfo + "\n"
        }
        
        // Add user preferences if available
        if let preferences = userPreferences, !preferences.isEmpty {
            prompt += "\nUSER PREFERENCES FROM PAST FEEDBACK:\n"
            for pref in preferences {
                prompt += "- \(pref)\n"
            }
        }
        
        prompt += """
        
        OPTIMIZATION INSTRUCTIONS:
        1. Identify overdue or soon-to-be-due tasks that need immediate attention
        2. Apply Eisenhower Matrix combined with ABC prioritization:
           - A1: Urgent & Important (do immediately)
           - A2: Important but not urgent (schedule)
           - B1: Urgent but not important (delegate if possible)
           - B2: Routine tasks
           - C: Nice to have
        3. Consider task duration when planning daily schedule - ensure realistic time allocation
        4. Identify "quick wins" - tasks that are:
           - Short duration (< 30 minutes)
           - No dependencies
           - High impact or satisfaction
        5. Find tasks that could be:
           - Batched together (similar context or tools)
           - Delegated (based on tags or patterns)
           - Automated (repetitive tasks)
           - Deleted (no longer relevant)
        6. Consider project deadlines and area balance
        7. Respect recurring tasks and their schedules
        8. Identify blocked tasks that depend on other incomplete tasks
        
        Provide specific, actionable recommendations for each task category. Focus on creating a balanced, achievable plan that maximizes productivity while preventing burnout.
        """
        
        return prompt
    }
    
    // MARK: - Workload Analysis
    
    /// Generates a prompt for analyzing workload distribution and providing suggestions
    /// - Parameters:
    ///   - workloads: Array of daily workload data
    ///   - insights: Analyzed insights from the workload data
    /// - Returns: A formatted prompt string
    static func workloadAnalysis(
        workloads: [WorkloadAnalyzer.DailyWorkload],
        insights: WorkloadAnalyzer.WorkloadInsight
    ) -> String {
        var prompt = """
        Analyze this workload distribution and provide actionable suggestions for better task management.
        
        Current Situation:
        - Average workload score: \(String(format: "%.0f", insights.averageWorkloadScore))/100
        - Overloaded days: \(insights.overloadedDays.count)
        - Days with light workload: \(insights.lightDays.count)
        
        """
        
        if let peakDay = insights.peakDay {
            prompt += """
            
            Peak workload day: \(peakDay.date.formatted(date: .complete, time: .omitted))
            - Tasks: \(peakDay.taskCount)
            - Total duration: \(WorkloadAnalyzer.formatDuration(peakDay.totalEstimatedDuration))
            - High priority tasks: \(peakDay.highPriorityCount)
            
            """
        }
        
        if !insights.overloadedDays.isEmpty {
            prompt += "\nOverloaded days details:\n"
            for day in insights.overloadedDays.prefix(3) {
                prompt += """
                - \(day.date.formatted(date: .abbreviated, time: .omitted)): \(day.taskCount) tasks, \(WorkloadAnalyzer.formatDuration(day.totalEstimatedDuration))
                
                """
            }
        }
        
        prompt += """
        
        Provide:
        1. Analysis of the workload pattern
        2. Specific recommendations for balancing the workload
        3. Time management strategies
        4. Warning signs to watch for
        5. Productivity tips based on the distribution
        
        Keep suggestions practical and actionable. Focus on sustainable productivity.
        """
        
        return prompt
    }
    
    // MARK: - Recurrence Pattern Detection
    
    /// Generates a prompt for detecting patterns in completed tasks
    /// - Parameters:
    ///   - completedTasks: Array of completed tasks with their completion dates
    ///   - timeFrame: Time frame to analyze (e.g., "last 30 days")
    /// - Returns: A formatted prompt string
    static func recurrencePatternDetection(
        completedTasks: [(title: String, completedAt: Date, projectName: String?, tags: [String])],
        timeFrame: String
    ) -> String {
        var prompt = """
        Analyze these completed tasks from the \(timeFrame) to identify potential recurring patterns.
        
        COMPLETED TASKS:
        """
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        
        for task in completedTasks {
            prompt += "\n- \"\(task.title)\" completed on \(dateFormatter.string(from: task.completedAt))"
            if let project = task.projectName {
                prompt += " (Project: \(project))"
            }
            if !task.tags.isEmpty {
                prompt += " [Tags: \(task.tags.joined(separator: ", "))]"
            }
        }
        
        prompt += """
        
        
        ANALYSIS REQUIRED:
        1. Identify tasks that appear to be recurring (similar titles, regular intervals)
        2. Detect weekly patterns (e.g., "Weekly team meeting" every Monday)
        3. Find monthly patterns (e.g., "Pay rent" on the 1st of each month)
        4. Spot project-related patterns (e.g., sprint reviews, status updates)
        5. Identify context-based patterns (e.g., weekend chores, workday routines)
        
        For each detected pattern, provide:
        - Task name pattern
        - Suggested recurrence rule (daily, weekly, monthly, etc.)
        - Confidence level (high, medium, low)
        - Reasoning for the suggestion
        
        Focus on patterns that would genuinely help the user by automating task creation.
        """
        
        return prompt
    }
    
    // MARK: - Future Prompts
    // Add more prompt generation methods here as new AI features are added
}
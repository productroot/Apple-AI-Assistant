//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels
import Observation

@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var sessionCount: Int = 1
    var instructions: String = "You are a helpful, friendly AI assistant. Engage in natural conversation and provide thoughtful, detailed responses."
    var errorMessage: String?
    var showError: Bool = false
    var hasCalendarContext: Bool = false
    var hasRemindersContext: Bool = false
    var selectedPersonalityTraits: Set<PersonalityTrait> = [] {
        didSet {
            savePersonalityTraits()
            updateInstructionsWithTraits()
        }
    }
    var customInstructions: String = "" {
        didSet {
            saveCustomInstructions()
            updateInstructionsWithTraits()
        }
    }

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession
    private var calendarTool: CalendarTool?
    private var remindersTool: RemindersTool?
    private var tasksViewModel: TasksViewModel?
    
    // MARK: - Private Properties
    
    private let defaultInstructions = "You are a helpful, friendly AI assistant. Engage in natural conversation and provide thoughtful, detailed responses."
    private let personalityTraitsKey = "chatPersonalityTraits"
    private let customInstructionsKey = "chatCustomInstructions"
    
    // MARK: - Feedback State
    
    private(set) var feedbackState: [Transcript.Entry.ID: LanguageModelFeedbackAttachment.Sentiment] = [:]

    // MARK: - Initialization

    init(tasksViewModel: TasksViewModel? = nil) {
        self.tasksViewModel = tasksViewModel
        self.session = LanguageModelSession(
            instructions: Instructions(defaultInstructions)
        )
        loadPersonalityTraits()
        loadCustomInstructions()
        updateInstructionsWithTraits()
    }
    
    // MARK: - Calendar Context
    
    @MainActor
    func updateCalendarContext() {
        hasCalendarContext = true
        calendarTool = CalendarTool()
        
        // Build tools array with all active tools
        var tools: [any Tool] = [calendarTool!]
        if let remindersTool = remindersTool {
            tools.append(remindersTool)
        }
        
        // Build combined instructions
        var combinedInstructions = "You are a helpful, friendly AI assistant with access to the user's calendar."
        
        if hasRemindersContext {
            combinedInstructions += " You also have access to the user's reminders."
        }
        
        combinedInstructions += """
         
        You can help manage calendar events, check schedules, and provide information about upcoming events.
        When the user asks about their calendar, schedule, or events, use the manageCalendar tool to access their calendar data.
        """
        
        if hasRemindersContext {
            combinedInstructions += """
            
            You can also help create, manage, and query reminders based on natural language requests.
            """
        }
        
        combinedInstructions += """
        
        Always be specific about dates and times when discussing calendar events.
        
        IMPORTANT:
        - Today is \(Date().formatted(date: .complete, time: .omitted))
        - Current time is \(Date().formatted(date: .omitted, time: .standard))
        - User's timezone is \(TimeZone.current.identifier)
        
        For calendar queries:
        - When user asks for a specific day (like "Monday"), calculate the correct daysAhead value to reach that day
        - For example, if today is Friday and user asks for Monday, that's 3 days ahead, not 1
        - The query action uses daysAhead parameter which counts from today
        - Always verify you're calculating the correct number of days to the requested date
        """
        
        if hasRemindersContext {
            combinedInstructions += """
            
            
            For reminders:
            - When parsing dates from natural language, consider relative terms like "tomorrow", "next week", etc.
            - For priorities, support: none, low, medium, high, and ASAP
            - Be helpful in interpreting the user's intent and provide clear confirmation of actions taken
            - When confirming reminder creation or updates, DO NOT mention the reminder ID - just confirm the action, title, date/time, and priority
            - If the user has enabled "Create Tasks from Chat Reminders" in settings, a corresponding task will also be created automatically
            """
        }
        
        self.session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(combinedInstructions)
        )
    }
    
    @MainActor
    func removeCalendarContext() {
        hasCalendarContext = false
        calendarTool = nil
        
        // If reminders context is still active, keep the reminders tool
        if hasRemindersContext, let remindersTool = remindersTool {
            let remindersInstructions = """
            You are a helpful, friendly AI assistant with access to the user's reminders. 
            You can help create, manage, and query reminders based on natural language requests.
            When the user asks about their reminders or wants to create/manage reminders, use the manageReminders tool.
            
            IMPORTANT: 
            - Today is \(Date().formatted(date: .complete, time: .omitted))
            - Current time is \(Date().formatted(date: .omitted, time: .standard))
            - User's timezone is \(TimeZone.current.identifier)
            - When parsing dates from natural language, consider relative terms like "tomorrow", "next week", etc.
            - For priorities, support: none, low, medium, high, and ASAP
            - Be helpful in interpreting the user's intent and provide clear confirmation of actions taken
            - When confirming reminder creation or updates, DO NOT mention the reminder ID - just confirm the action, title, date/time, and priority
            - If the user has enabled "Create Tasks from Chat Reminders" in settings, a corresponding task will also be created automatically
            """
            
            self.session = LanguageModelSession(
                tools: [remindersTool],
                instructions: Instructions(remindersInstructions)
            )
        } else {
            // Reset session to default instructions without tools
            self.session = LanguageModelSession(
                instructions: Instructions(instructions)
            )
        }
    }
    
    // MARK: - Reminders Context
    
    @MainActor
    func updateRemindersContext() {
        hasRemindersContext = true
        remindersTool = RemindersTool()
        
        // Build tools array with all active tools
        var tools: [any Tool] = []
        if let calendarTool = calendarTool {
            tools.append(calendarTool)
        }
        tools.append(remindersTool!)
        
        // Build combined instructions
        var combinedInstructions = "You are a helpful, friendly AI assistant with access to the user's reminders."
        
        if hasCalendarContext {
            combinedInstructions += " You also have access to the user's calendar."
        }
        
        combinedInstructions += """
         
        You can help create, manage, and query reminders based on natural language requests.
        When the user asks about their reminders or wants to create/manage reminders, use the manageReminders tool.
        """
        
        if hasCalendarContext {
            combinedInstructions += """
            
            You can also help manage calendar events, check schedules, and provide information about upcoming events.
            """
        }
        
        combinedInstructions += """
        
        
        IMPORTANT: 
        - Today is \(Date().formatted(date: .complete, time: .omitted))
        - Current time is \(Date().formatted(date: .omitted, time: .standard))
        - User's timezone is \(TimeZone.current.identifier)
        
        For reminders:
        - When parsing dates from natural language, consider relative terms like "tomorrow", "next week", etc.
        - For priorities, support: none, low, medium, high, and ASAP
        - Be helpful in interpreting the user's intent and provide clear confirmation of actions taken
        - When confirming reminder creation or updates, DO NOT mention the reminder ID - just confirm the action, title, date/time, and priority
        - If the user has enabled "Create Tasks from Chat Reminders" in settings, a corresponding task will also be created automatically
        """
        
        if hasCalendarContext {
            combinedInstructions += """
            
            
            For calendar queries:
            - When user asks for a specific day (like "Monday"), calculate the correct daysAhead value to reach that day
            - For example, if today is Friday and user asks for Monday, that's 3 days ahead, not 1
            - The query action uses daysAhead parameter which counts from today
            - Always verify you're calculating the correct number of days to the requested date
            """
        }
        
        self.session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(combinedInstructions)
        )
    }
    
    @MainActor
    func removeRemindersContext() {
        hasRemindersContext = false
        remindersTool = nil
        
        // If calendar context is still active, keep the calendar tool
        if hasCalendarContext, let calendarTool = calendarTool {
            let calendarInstructions = """
            You are a helpful, friendly AI assistant with access to the user's calendar. 
            You can help manage calendar events, check schedules, and provide information about upcoming events.
            When the user asks about their calendar, schedule, or events, use the manageCalendar tool to access their calendar data.
            Always be specific about dates and times when discussing calendar events.
            
            IMPORTANT: When querying events:
            - Today is \(Date().formatted(date: .complete, time: .omitted))
            - When user asks for a specific day (like "Monday"), calculate the correct daysAhead value to reach that day
            - For example, if today is Friday and user asks for Monday, that's 3 days ahead, not 1
            - The query action uses daysAhead parameter which counts from today
            - Always verify you're calculating the correct number of days to the requested date
            """
            
            self.session = LanguageModelSession(
                tools: [calendarTool],
                instructions: Instructions(calendarInstructions)
            )
        } else {
            // Reset session to default instructions without tools
            self.session = LanguageModelSession(
                instructions: Instructions(instructions)
            )
        }
    }

    // MARK: - Public Methods

    @MainActor
    func sendMessage(_ content: String) async {
        isLoading = session.isResponding

        do {
            // Stream response from current session
            let responseStream = session.streamResponse(to: Prompt(content))

            for try await _ in responseStream {
                // The streaming automatically updates the session transcript
            }
            
            // After streaming completes, check if we need to create tasks from reminders
            await checkAndCreateTasksFromReminders()

        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Handle context window exceeded by summarizing and creating new session
            await handleContextWindowExceeded(userMessage: content)

        } catch {
            // Handle other errors by showing an error message
            errorMessage = error.localizedDescription
            showError = true
        }

        isLoading = session.isResponding
    }

    @MainActor
    func submitFeedback(for entryID: Transcript.Entry.ID, sentiment: LanguageModelFeedbackAttachment.Sentiment) {
        guard let entryIndex = session.transcript.firstIndex(where: { $0.id == entryID }) else {
            // Log error in debug mode only
            #if DEBUG
            print("Error: Could not find transcript entry for feedback.")
            #endif
            return
        }

        // Store the feedback state
        feedbackState[entryID] = sentiment

        let outputEntry = session.transcript[entryIndex]
        let inputEntries = session.transcript[..<entryIndex]

        let feedback = LanguageModelFeedbackAttachment(
            input: Array(inputEntries),
            output: [outputEntry],
            sentiment: sentiment
        )

        // In a real app, you would serialize this and attach it to a Feedback Assistant report.
        // For this example, we'll print the JSON representation to the console.
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(feedback)
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            #if DEBUG
            print("\n--- Feedback Submitted ---")
            print(jsonString)
            print("------------------------\n")
            #endif
        } catch {
            #if DEBUG
            print("Error encoding feedback: \(error)")
            #endif
        }
    }
    
    @MainActor
    func getFeedback(for entryID: Transcript.Entry.ID) -> LanguageModelFeedbackAttachment.Sentiment? {
        return feedbackState[entryID]
    }

    @MainActor
    func clearChat() {
        sessionCount = 1
        feedbackState.removeAll()
        
        // Rebuild session with active contexts
        var tools: [any Tool] = []
        var contextInstructions = instructions
        
        if hasCalendarContext, let calendarTool = calendarTool {
            tools.append(calendarTool)
        }
        
        if hasRemindersContext, let remindersTool = remindersTool {
            tools.append(remindersTool)
        }
        
        // Build combined instructions if we have any tools
        if !tools.isEmpty {
            var combinedInstructions = "You are a helpful, friendly AI assistant"
            
            if hasCalendarContext {
                combinedInstructions += " with access to the user's calendar. You can help manage calendar events, check schedules, and provide information about upcoming events."
            }
            
            if hasRemindersContext {
                if hasCalendarContext {
                    combinedInstructions += " You also have"
                } else {
                    combinedInstructions += " with"
                }
                combinedInstructions += " access to the user's reminders. You can help create, manage, and query reminders based on natural language requests."
            }
            
            combinedInstructions += """
            
            
            IMPORTANT:
            - Today is \(Date().formatted(date: .complete, time: .omitted))
            - Current time is \(Date().formatted(date: .omitted, time: .standard))
            - User's timezone is \(TimeZone.current.identifier)
            """
            
            if hasCalendarContext {
                combinedInstructions += """
                
                
                For calendar queries:
                - When user asks for a specific day (like "Monday"), calculate the correct daysAhead value to reach that day
                - For example, if today is Friday and user asks for Monday, that's 3 days ahead, not 1
                - The query action uses daysAhead parameter which counts from today
                - Always verify you're calculating the correct number of days to the requested date
                """
            }
            
            if hasRemindersContext {
                combinedInstructions += """
                
                
                For reminders:
                - When parsing dates from natural language, consider relative terms like "tomorrow", "next week", etc.
                - For priorities, support: none, low, medium, high, and ASAP
                - Be helpful in interpreting the user's intent and provide clear confirmation of actions taken
                """
            }
            
            contextInstructions = combinedInstructions
        }
        
        session = LanguageModelSession(
            tools: tools,
            instructions: Instructions(contextInstructions)
        )
    }
    
    @MainActor
    func updateInstructions(_ newInstructions: String) {
        instructions = newInstructions
        // Create a new session with updated instructions
        // Note: The transcript is read-only, so we start fresh with new instructions
        session = LanguageModelSession(
            instructions: Instructions(instructions)
        )
    }

    // MARK: - Private Methods

    @MainActor
    private func handleContextWindowExceeded(userMessage: String) async {
        isSummarizing = true

        do {
            let summary = try await generateConversationSummary()
            createNewSessionWithContext(summary: summary)
            isSummarizing = false

            try await respondWithNewSession(to: userMessage)
        } catch {
            handleSummarizationError(error)
            errorMessage = "Failed to summarize conversation: \(error.localizedDescription)"
            showError = true
        }
    }

    private func createConversationText() -> String {
        return session.transcript.compactMap { entry in
            switch entry {
            case .prompt(let prompt):
                let text = prompt.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                return "User: \(text)"
            case .response(let response):
                let text = response.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                return "Assistant: \(text)"
            default:
                return nil
            }
        }.joined(separator: "\n\n")
    }


    @MainActor
    private func generateConversationSummary() async throws -> ConversationSummary {
        let summarySession = LanguageModelSession(
            instructions: Instructions(
                "You are an expert at summarizing conversations. Create comprehensive summaries that preserve all important context and details."
            )
        )

        let conversationText = createConversationText()
        let summaryPrompt = """
      Please summarize the following entire conversation comprehensively. Include all key points, topics discussed, user preferences, and important context that would help continue the conversation naturally:
      
      \(conversationText)
      """

        let summaryResponse = try await summarySession.respond(
            to: Prompt(summaryPrompt),
            generating: ConversationSummary.self
        )

        return summaryResponse.content
    }

    private func createNewSessionWithContext(summary: ConversationSummary) {
        let baseInstructions = hasCalendarContext ? """
        You are a helpful, friendly AI assistant with access to the user's calendar. 
        You can help manage calendar events, check schedules, and provide information about upcoming events.
        When the user asks about their calendar, schedule, or events, use the manageCalendar tool to access their calendar data.
        Always be specific about dates and times when discussing calendar events.
        
        IMPORTANT: When querying events:
        - Today is \(Date().formatted(date: .complete, time: .omitted))
        - When user asks for a specific day (like "Monday"), calculate the correct daysAhead value to reach that day
        - For example, if today is Friday and user asks for Monday, that's 3 days ahead, not 1
        - The query action uses daysAhead parameter which counts from today
        - Always verify you're calculating the correct number of days to the requested date
        """ : instructions
        
        let contextInstructions = """
      \(baseInstructions)
      
      You are continuing a conversation with a user. Here's a summary of your previous conversation:
      
      CONVERSATION SUMMARY:
      \(summary.summary)
      
      KEY TOPICS DISCUSSED:
      \(summary.keyTopics.map { "• \($0)" }.joined(separator: "\n"))
      
      USER PREFERENCES/REQUESTS:
      \(summary.userPreferences.map { "• \($0)" }.joined(separator: "\n"))
      
      Continue the conversation naturally, referencing this context when relevant. The user's next message is a continuation of your previous discussion.
      """

        if hasCalendarContext, let calendarTool = calendarTool {
            session = LanguageModelSession(
                tools: [calendarTool],
                instructions: Instructions(contextInstructions)
            )
        } else {
            session = LanguageModelSession(instructions: Instructions(contextInstructions))
        }
        sessionCount += 1
    }

    @MainActor
    private func respondWithNewSession(to userMessage: String) async throws {
        let responseStream = session.streamResponse(to: Prompt(userMessage))

        for try await _ in responseStream {
            // The streaming automatically updates the session transcript
        }
    }

    @MainActor
    private func handleSummarizationError(_ error: Error) {
        isSummarizing = false
        errorMessage = error.localizedDescription
        showError = true
    }
    
    @MainActor
    func dismissError() {
        showError = false
        errorMessage = nil
    }
    
    // MARK: - Task Creation from Reminders
    
    @MainActor
    private func checkAndCreateTasksFromReminders() async {
        // Check if the setting is enabled
        guard UserDefaults.standard.bool(forKey: "createTasksFromChatReminders"),
              let tasksViewModel = tasksViewModel,
              hasRemindersContext else { return }
        
        // Look for recent tool outputs that indicate reminder creation
        let recentEntries = session.transcript.suffix(5) // Check last 5 entries
        
        for entry in recentEntries {
            if case .toolOutput(let toolOutput) = entry {
                // Extract text from tool output
                let text = toolOutput.segments.compactMap { segment in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined()
                
                // Check if this is a successful reminder creation
                if text.contains("\"status\": \"success\"") && text.contains("\"message\": \"Reminder created successfully\"") {
                    print("🔍 Found reminder creation JSON: \(text)")
                    
                    // Parse the reminder details from the JSON
                    if let reminderInfo = parseReminderFromJSON(text) {
                        print("✅ Successfully parsed reminder: \(reminderInfo)")
                        // Create a corresponding task
                        await createTaskFromReminder(reminderInfo, tasksViewModel: tasksViewModel)
                    } else {
                        print("❌ Failed to parse reminder from JSON")
                    }
                }
            }
        }
    }
    
    private func parseReminderFromJSON(_ json: String) -> (title: String, notes: String?, dueDate: Date?, priority: String)? {
        // Simple parsing - in production, use proper JSON decoding
        var title: String?
        var notes: String?
        var dueDate: Date?
        var priority = "medium"
        
        // Extract title
        if let titleRange = json.range(of: "\"title\": \""),
           let endRange = json[titleRange.upperBound...].range(of: "\"") {
            title = String(json[titleRange.upperBound..<endRange.lowerBound])
        }
        
        // Extract notes if present
        if let notesRange = json.range(of: "\"notes\": \""),
           let endRange = json[notesRange.upperBound...].range(of: "\"") {
            notes = String(json[notesRange.upperBound..<endRange.lowerBound])
        }
        
        // Extract due date
        if let dueDateRange = json.range(of: "\"dueDate\": \""),
           let endRange = json[dueDateRange.upperBound...].range(of: "\"") {
            let dueDateString = String(json[dueDateRange.upperBound..<endRange.lowerBound])
            
            // Don't try to parse if the date string is empty
            if !dueDateString.isEmpty {
                // Parse the date string using DateFormatter with medium date and short time
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                formatter.locale = Locale(identifier: "en_US")
                
                // First try to parse with the standard format
                dueDate = formatter.date(from: dueDateString)
                
                // If that fails, try alternate formats
                if dueDate == nil {
                    formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
                    dueDate = formatter.date(from: dueDateString)
                }
                
                if dueDate == nil {
                    formatter.dateFormat = "MMM dd, yyyy 'at' h:mm a"
                    dueDate = formatter.date(from: dueDateString)
                }
                
                if dueDate == nil {
                    print("⚠️ Failed to parse date: \(dueDateString)")
                }
            }
        }
        
        // Extract priority
        if let priorityRange = json.range(of: "\"priority\": \""),
           let endRange = json[priorityRange.upperBound...].range(of: "\"") {
            let priorityString = String(json[priorityRange.upperBound..<endRange.lowerBound]).lowercased()
            
            // Map reminder priority to task priority
            switch priorityString {
            case "high", "asap":
                priority = "high"
            case "medium":
                priority = "medium"
            case "low", "none":
                priority = "low"
            default:
                priority = "medium"
            }
        }
        
        guard let title = title else { return nil }
        
        return (title: title, notes: notes, dueDate: dueDate, priority: priority)
    }
    
    @MainActor
    private func createTaskFromReminder(_ reminderInfo: (title: String, notes: String?, dueDate: Date?, priority: String), tasksViewModel: TasksViewModel) async {
        // Create a new task
        let task = TodoTask(
            title: reminderInfo.title,
            notes: reminderInfo.notes ?? "",
            scheduledDate: reminderInfo.dueDate,  // Use scheduledDate instead of dueDate
            priority: TodoTask.Priority(rawValue: reminderInfo.priority) ?? .medium,
            createdFromReminder: true
        )
        
        // Add to tasks
        tasksViewModel.addTask(task)
        
        print("📝 Created task from reminder: \(task.title)")
        print("   Scheduled date: \(task.scheduledDate?.formatted() ?? "No scheduled date")")
        print("   Priority: \(task.priority.rawValue)")
        print("   Notes: \(task.notes.isEmpty ? "No notes" : task.notes)")
    }
    
    // MARK: - Personality Traits Management
    
    private func loadPersonalityTraits() {
        print("📖 Loading personality traits from storage")
        
        // Try to load from iCloud first
        if let cloudData = iCloudService.shared.getData(forKey: personalityTraitsKey),
           let traits = try? JSONDecoder().decode(Set<PersonalityTrait>.self, from: cloudData) {
            print("☁️ Loaded personality traits from iCloud: \(traits.count) traits")
            selectedPersonalityTraits = traits
        } else if let localData = UserDefaults.standard.data(forKey: personalityTraitsKey),
                  let traits = try? JSONDecoder().decode(Set<PersonalityTrait>.self, from: localData) {
            print("💾 Loaded personality traits from UserDefaults: \(traits.count) traits")
            selectedPersonalityTraits = traits
        } else {
            print("❌ No saved personality traits found")
        }
    }
    
    private func savePersonalityTraits() {
        print("💾 Saving personality traits")
        
        if let data = try? JSONEncoder().encode(selectedPersonalityTraits) {
            UserDefaults.standard.set(data, forKey: personalityTraitsKey)
            iCloudService.shared.setData(data, forKey: personalityTraitsKey)
            print("✅ Saved \(selectedPersonalityTraits.count) personality traits")
        }
    }
    
    private func loadCustomInstructions() {
        print("📖 Loading custom instructions from storage")
        
        // Try to load from iCloud first
        if let cloudInstructions = iCloudService.shared.getString(forKey: customInstructionsKey) {
            print("☁️ Loaded custom instructions from iCloud")
            customInstructions = cloudInstructions
        } else if let localInstructions = UserDefaults.standard.string(forKey: customInstructionsKey) {
            print("💾 Loaded custom instructions from UserDefaults")
            customInstructions = localInstructions
        } else {
            print("❌ No saved custom instructions found")
        }
    }
    
    private func saveCustomInstructions() {
        print("💾 Saving custom instructions")
        
        UserDefaults.standard.set(customInstructions, forKey: customInstructionsKey)
        iCloudService.shared.setString(customInstructions, forKey: customInstructionsKey)
        print("✅ Saved custom instructions")
    }
    
    private func updateInstructionsWithTraits() {
        print("🔄 Updating instructions with personality traits")
        
        var combinedInstructions = defaultInstructions
        
        // Add personality trait instructions
        if !selectedPersonalityTraits.isEmpty {
            let traitInstructions = selectedPersonalityTraits
                .map { $0.instruction }
                .joined(separator: " ")
            combinedInstructions += " " + traitInstructions
            print("   Added \(selectedPersonalityTraits.count) personality traits")
        }
        
        // Add custom instructions
        if !customInstructions.isEmpty {
            combinedInstructions += " " + customInstructions
            print("   Added custom instructions")
        }
        
        instructions = combinedInstructions
        print("✅ Instructions updated")
    }
    
    @MainActor
    func resetInstructions() {
        print("🔄 Resetting instructions to default")
        selectedPersonalityTraits.removeAll()
        customInstructions = ""
        instructions = defaultInstructions
        
        // Clear from storage
        UserDefaults.standard.removeObject(forKey: personalityTraitsKey)
        UserDefaults.standard.removeObject(forKey: customInstructionsKey)
        iCloudService.shared.removeData(forKey: personalityTraitsKey)
        iCloudService.shared.removeData(forKey: customInstructionsKey)
        
        // Update session with default instructions
        updateInstructions(defaultInstructions)
        print("✅ Instructions reset to default")
    }
}

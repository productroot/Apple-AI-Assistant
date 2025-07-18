//
//  DataModels.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

// MARK: - Chat Models

struct ChatMessage: Identifiable, Equatable {
  let id: UUID
  let entryID: Transcript.Entry.ID?
  let content: AttributedString
  let isFromUser: Bool
  let timestamp: Date
  let isContextSummary: Bool

  init(content: String, isFromUser: Bool, isContextSummary: Bool = false) {
    self.init(entryID: nil, content: content, isFromUser: isFromUser, isContextSummary: isContextSummary)
  }
  
  init(entryID: Transcript.Entry.ID?, content: String, isFromUser: Bool, isContextSummary: Bool = false) {
    self.id = UUID()
    self.entryID = entryID
    self.content = AttributedString(content)
    self.isFromUser = isFromUser
    self.timestamp = Date()
    self.isContextSummary = isContextSummary
  }
  
  init(content: AttributedString, isFromUser: Bool, isContextSummary: Bool = false) {
    self.init(id: UUID(), content: content, isFromUser: isFromUser, timestamp: Date(), isContextSummary: isContextSummary)
  }

  init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false)
  {
    self.init(id: id, content: AttributedString(content), isFromUser: isFromUser, timestamp: timestamp, isContextSummary: isContextSummary)
  }
  
  init(id: UUID, content: AttributedString, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false)
  {
    self.id = id
    self.entryID = nil
    self.content = content
    self.isFromUser = isFromUser
    self.timestamp = timestamp
    self.isContextSummary = isContextSummary
  }
}

@Generable
struct ConversationSummary {
  @Guide(
    description:
      "A comprehensive summary of the entire conversation including all key points, topics discussed, questions asked, and responses provided. Include important context and details that would help continue the conversation naturally."
  )
  let summary: String

  @Guide(description: "The main topics or themes that were discussed in the conversation")
  let keyTopics: [String]

  @Guide(
    description: "Any specific requests, preferences, or important information the user mentioned")
  let userPreferences: [String]
}

// MARK: - Request/Response Models

struct RequestResponsePair: Identifiable {
  let id = UUID()
  let request: String
  let response: String
  let isError: Bool
  let timestamp: Date
  
  init(request: String, response: String, isError: Bool = false) {
    self.request = request
    self.response = response
    self.isError = isError
    self.timestamp = Date()
  }
}

// MARK: - Book Recommendation Models

@Generable
struct BookRecommendation {
  @Guide(description: "The title of the book")
  let title: String

  @Guide(description: "The author's name")
  let author: String

  @Guide(description: "A brief description in 2-3 sentences")
  let description: String

  @Guide(description: "Genre of the book")
  let genre: Genre
}

@Generable
enum Genre {
  case fiction
  case nonFiction
  case mystery
  case romance
  case sciFi
  case fantasy
  case biography
  case history
}

// MARK: - Product Review Models

@Generable
struct ProductReview {
  @Guide(description: "Product name")
  let productName: String

  @Guide(description: "Rating from 1 to 5")
  let rating: Int

  @Guide(description: "Review text between 50-200 words")
  let reviewText: String

  @Guide(description: "Would recommend this product")
  let recommendation: String

  @Guide(description: "Key pros of the product")
  let pros: [String]

  @Guide(description: "Key cons of the product")
  let cons: [String]
}

// MARK: - Creative Writing Models

@Generable
struct StoryOutline {
  @Guide(description: "The title of the story")
  let title: String

  @Guide(description: "Main character name and brief description")
  let protagonist: String

  @Guide(description: "The central conflict or challenge")
  let conflict: String

  @Guide(description: "The setting where the story takes place")
  let setting: String

  @Guide(description: "Story genre")
  let genre: StoryGenre

  @Guide(description: "Major themes explored in the story")
  let themes: [String]
}

@Generable
enum StoryGenre {
  case adventure
  case mystery
  case romance
  case thriller
  case fantasy
  case sciFi
  case horror
  case comedy
}

// MARK: - Business Models

@Generable
struct BusinessIdea {
  @Guide(description: "Name of the business")
  let name: String

  @Guide(description: "Brief description of what the business does")
  let description: String

  @Guide(description: "Target market or customer base")
  let targetMarket: String

  @Guide(description: "Primary revenue model")
  let revenueModel: String

  @Guide(description: "Key advantages or unique selling points")
  let advantages: [String]

  @Guide(description: "Initial startup costs estimate")
  let estimatedStartupCost: String

  @Guide(description: "Expected timeline or phases for launch and growth")
  let timeline: String?
}

// MARK: - Project Description Model

@Generable
struct ProjectDescription {
  @Guide(description: "A comprehensive description of the project's purpose, goals, and scope. Should be informative and inspiring.")
  let description: String
  
  @Guide(description: "Key objectives or deliverables for this project")
  let objectives: [String]
  
  @Guide(description: "Expected outcomes or benefits of completing this project")
  let expectedOutcomes: [String]
  
  @Guide(description: "Primary focus area or category of the project based on its area assignment")
  let focusArea: String?
}

// MARK: - Task Checklist Model

@Generable
struct TaskChecklist {
  @Guide(description: "A list of actionable checklist items for completing the task. Each item should be specific, clear, and achievable.")
  let items: [String]
  
  @Guide(description: "Estimated time in minutes for completing all checklist items")
  let estimatedTotalMinutes: Int?
  
  @Guide(description: "Suggested order of completion: 'sequential' if items should be done in order, 'parallel' if they can be done in any order")
  let completionOrder: String?
}

// MARK: - Task Duration Estimate Model

@Generable
struct TaskDurationEstimate {
  @Guide(description: "Estimated time in minutes for completing the task based on its title, description, checklist items and historical data. Provide a realistic estimate considering the complexity and scope of the task.")
  let minutes: Int
}

// MARK: - Task Optimization Models

@Generable
struct TaskOptimizationAnalysis {
  @Guide(description: "List of overdue tasks or tasks requiring immediate attention")
  let urgentTasks: [OptimizedTask]
  
  @Guide(description: "Tasks recommended to complete today based on priority, deadlines, and estimated duration")
  let todayTasks: [OptimizedTask]
  
  @Guide(description: "Tasks to complete this week")
  let thisWeekTasks: [OptimizedTask]
  
  @Guide(description: "Tasks that can be done later without negative impact")
  let laterTasks: [OptimizedTask]
  
  @Guide(description: "Tasks that are blocked by other tasks or dependencies")
  let blockedTasks: [OptimizedTask]
  
  @Guide(description: "Tasks that could be delegated or automated based on patterns and tags")
  let delegatableTasks: [OptimizedTask]
  
  @Guide(description: "Quick win tasks - short duration, low complexity, high impact")
  let quickWins: [OptimizedTask]
  
  @Guide(description: "Overall optimization insights and recommendations")
  let insights: [String]
}

@Generable
struct OptimizedTask {
  @Guide(description: "The task ID (UUID string)")
  let taskId: String
  
  @Guide(description: "Recommended priority using Eisenhower matrix combined with ABC method: A1 (urgent & important), A2 (important not urgent), B1 (urgent not important), B2 (routine), C (nice to have)")
  let recommendedPriority: String
  
  @Guide(description: "Reason for the recommendation")
  let reasoning: String
  
  @Guide(description: "Suggested actions: 'do_now', 'schedule', 'delegate', 'automate', 'delete', 'batch_with_similar'")
  let suggestedAction: String
  
  @Guide(description: "If batching is suggested, list of similar task IDs to batch with")
  let batchWithTaskIds: [String]?
  
  @Guide(description: "Estimated focus time needed in minutes")
  let estimatedFocusMinutes: Int?
  
  @Guide(description: "Best time slot for this task: 'morning', 'afternoon', 'evening', 'anytime'")
  let optimalTimeSlot: String?
}

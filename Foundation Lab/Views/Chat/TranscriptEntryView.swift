//
//  TranscriptEntryView.swift
//  FoundationLab
//
//  Created by Assistant on 7/1/25.
//

import SwiftUI
import FoundationModels

struct TranscriptEntryView: View {
    let entry: Transcript.Entry
    
    var body: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = extractText(from: prompt.segments), !text.isEmpty {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: true))
                    .id(entry.id)
            }
            
        case .response(let response):
            if let text = extractText(from: response.segments), !text.isEmpty, text != "null" {
                MessageBubbleView(message: ChatMessage(entryID: entry.id, content: text, isFromUser: false))
                    .id(entry.id)
            }
            
        case .toolCalls(let toolCalls):
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { index, toolCall in
                let toolDisplayName = formatToolName(toolCall.toolName)
                MessageBubbleView(message: ChatMessage(
                    entryID: entry.id,
                    content: "🔧 Tool used: \(toolDisplayName)",
                    isFromUser: false
                ))
                .id("\(entry.id)-tool-\(index)")
            }
            
        case .toolOutput(let toolOutput):
            // First try to extract text from segments
            if let text = extractText(from: toolOutput.segments), !text.isEmpty {
                // Check if the text looks like JSON (starts with { and contains "status")
                if text.hasPrefix("{") && text.contains("\"status\"") {
                    // This is raw JSON output - show a simple success message instead
                    let isSuccess = text.contains("\"success\"")
                    let message = isSuccess ? "✅ Tool completed successfully" : "❌ Tool failed"
                    MessageBubbleView(message: ChatMessage(
                        entryID: entry.id,
                        content: message,
                        isFromUser: false
                    ))
                    .id(entry.id)
                } else {
                    // This is formatted text - show it as is
                    MessageBubbleView(message: ChatMessage(
                        entryID: entry.id,
                        content: "🔧 Tool result: \(text)",
                        isFromUser: false
                    ))
                    .id(entry.id)
                    .animation(.easeInOut(duration: 0.3), value: text)
                }
            } else {
                // If no text segments, don't show anything
                // The AI will generate a proper response
                EmptyView()
            }
            
        case .instructions:
            // Don't show instructions in chat UI
            EmptyView()
            
        @unknown default:
            EmptyView()
        }
    }
    
    private func extractText(from segments: [Transcript.Segment]) -> String? {
        let text = segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")
        
        return text.isEmpty ? nil : text
    }
    
    private func formatToolName(_ toolName: String) -> String {
        switch toolName {
        case "manageReminders":
            return "Manage Reminders"
        case "manageCalendar":
            return "Manage Calendar"
        case "searchPokemon":
            return "Search Pokémon"
        case "getWeather":
            return "Get Weather"
        default:
            // Convert camelCase to Title Case
            let words = toolName.split { $0.isUppercase }
            if words.isEmpty {
                return toolName.capitalized
            }
            var result = ""
            var currentIndex = toolName.startIndex
            for word in words {
                if currentIndex < toolName.endIndex {
                    let char = toolName[currentIndex]
                    result += String(char).uppercased() + word
                    currentIndex = toolName.index(after: toolName.index(currentIndex, offsetBy: word.count))
                }
            }
            return result
        }
    }
    
    private func formatToolResult(_ toolOutput: Transcript.ToolOutput) -> String {
        // Don't show the raw tool output - the AI will generate a proper response
        // Return empty string to hide the technical JSON output
        return ""
    }
}
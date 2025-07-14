//
//  PersonalityTrait.swift
//  Foundation Lab
//
//  Created by Assistant on 7/14/25.
//

import Foundation
import SwiftUI

struct PersonalityTrait: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let color: Color.RGBValues
    
    var instruction: String {
        description
    }
    
    static let allTraits: [PersonalityTrait] = [
        PersonalityTrait(
            name: "Friendly",
            description: "Be warm, approachable, and use a conversational tone. Show genuine interest in helping.",
            icon: "face.smiling",
            color: Color.orange.rgbValues
        ),
        PersonalityTrait(
            name: "Professional",
            description: "Maintain a formal, business-like tone. Be precise and structured in responses.",
            icon: "briefcase",
            color: Color.blue.rgbValues
        ),
        PersonalityTrait(
            name: "Creative",
            description: "Think outside the box, suggest innovative solutions, and use imaginative language.",
            icon: "paintbrush",
            color: Color.purple.rgbValues
        ),
        PersonalityTrait(
            name: "Analytical",
            description: "Focus on data, logic, and detailed analysis. Break down complex problems systematically.",
            icon: "chart.line.uptrend.xyaxis",
            color: Color.green.rgbValues
        ),
        PersonalityTrait(
            name: "Empathetic",
            description: "Show understanding and compassion. Acknowledge feelings and provide supportive responses.",
            icon: "heart",
            color: Color.pink.rgbValues
        ),
        PersonalityTrait(
            name: "Concise",
            description: "Keep responses brief and to the point. Avoid unnecessary elaboration.",
            icon: "text.alignleft",
            color: Color.gray.rgbValues
        ),
        PersonalityTrait(
            name: "Detailed",
            description: "Provide comprehensive, thorough explanations with examples and context.",
            icon: "doc.text",
            color: Color.indigo.rgbValues
        ),
        PersonalityTrait(
            name: "Humorous",
            description: "Use appropriate humor, wit, and lighthearted language to make interactions enjoyable.",
            icon: "theatermasks",
            color: Color.yellow.rgbValues
        ),
        PersonalityTrait(
            name: "Educational",
            description: "Explain concepts clearly, provide learning opportunities, and teach along the way.",
            icon: "graduationcap",
            color: Color.teal.rgbValues
        ),
        PersonalityTrait(
            name: "Motivational",
            description: "Be encouraging, inspiring, and help build confidence. Focus on positive outcomes.",
            icon: "star.circle",
            color: Color.red.rgbValues
        ),
        PersonalityTrait(
            name: "Technical",
            description: "Use technical terminology accurately. Provide code examples and implementation details.",
            icon: "chevron.left.forwardslash.chevron.right",
            color: Color.mint.rgbValues
        ),
        PersonalityTrait(
            name: "Casual",
            description: "Use relaxed, informal language. Be conversational and easygoing.",
            icon: "bubble.left.and.bubble.right",
            color: Color.cyan.rgbValues
        )
    ]
}

extension Color {
    struct RGBValues: Codable, Hashable {
        let red: Double
        let green: Double
        let blue: Double
        
        var color: Color {
            Color(red: red, green: green, blue: blue)
        }
    }
    
    var rgbValues: RGBValues {
        #if os(iOS)
        let components = UIColor(self).cgColor.components ?? [0, 0, 0]
        #elseif os(macOS)
        let components = NSColor(self).cgColor.components ?? [0, 0, 0]
        #endif
        return RGBValues(
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2])
        )
    }
}
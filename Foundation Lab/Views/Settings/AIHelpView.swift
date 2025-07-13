//
//  AIHelpView.swift
//  Foundation Lab
//
//  Created by Assistant on 7/13/25.
//

import SwiftUI

struct AIHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.purple)
                            .symbolRenderingMode(.hierarchical)
                        
                        Text("AI Features Guide")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    Text("Discover how AI enhances your task management experience")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Features List
                VStack(spacing: 20) {
                    // Workload Balance
                    AIFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .blue,
                        title: "Workload Balance Assistant",
                        description: "Analyzes your task distribution across days and helps you balance your workload",
                        features: [
                            "Visual workload chart showing daily task distribution",
                            "Automatic detection of overloaded and light days",
                            "Smart suggestions for moving tasks to optimize your schedule",
                            "AI-powered insights about your work patterns"
                        ],
                        howToUse: "Access from Tasks view → AI Tools → Workload Balance"
                    )
                    
                    // Recurrence Pattern Detection
                    AIFeatureCard(
                        icon: "arrow.clockwise.circle.fill",
                        iconColor: .green,
                        title: "Intelligent Recurring Task Patterns",
                        description: "Automatically detects patterns in your completed tasks and suggests recurrence rules",
                        features: [
                            "Analyzes task history to find recurring patterns",
                            "Suggests daily, weekly, monthly, or custom recurrence",
                            "Confidence scoring for pattern reliability",
                            "Visual timeline of task occurrences"
                        ],
                        howToUse: "Access from Tasks view → AI Tools → Recurrence Patterns"
                    )
                    
                    // Task Checklist Generation
                    AIFeatureCard(
                        icon: "checklist",
                        iconColor: .orange,
                        title: "Smart Checklist Generation",
                        description: "AI generates relevant checklist items based on your task title and description",
                        features: [
                            "Context-aware checklist item suggestions",
                            "Breaks down complex tasks into actionable steps",
                            "Add generated items to existing checklists",
                            "Available in both task creation and editing"
                        ],
                        howToUse: "Tap 'Generate Checklist' button when creating or editing a task"
                    )
                    
                    // Duration Estimation
                    AIFeatureCard(
                        icon: "clock.fill",
                        iconColor: .purple,
                        title: "AI Duration Estimation",
                        description: "Estimates how long tasks will take based on their complexity and content",
                        features: [
                            "Analyzes task title, notes, and checklist items",
                            "Provides realistic time estimates",
                            "Learns from your task completion patterns",
                            "Helps with better time management"
                        ],
                        howToUse: "Select 'AI Estimate' from the duration menu when editing a task"
                    )
                    
                    // Contact Mentions
                    AIFeatureCard(
                        icon: "at",
                        iconColor: .indigo,
                        title: "Smart Contact Mentions",
                        description: "Mention contacts in tasks using @ symbol for better collaboration tracking",
                        features: [
                            "Type @ to search and mention contacts",
                            "Interactive contact pills in task display",
                            "Quick access to contact details",
                            "Works in both title and notes fields"
                        ],
                        howToUse: "Type @ followed by a space to search for contacts while creating or editing tasks"
                    )
                    
                    // Task Dependency Detection
                    AIFeatureCard(
                        icon: "network",
                        iconColor: .cyan,
                        title: "Task Dependency Detection",
                        description: "AI identifies dependencies between tasks and suggests optimal ordering",
                        features: [
                            "Automatic detection of task relationships",
                            "Visual dependency graph with zoom controls",
                            "Critical path identification",
                            "Bottleneck warnings and resolution suggestions",
                            "Cluster visualization for related tasks"
                        ],
                        howToUse: "Access from Tasks view → AI Tools → Task Dependencies"
                    )
                    
                    // Task Insights Dashboard
                    AIFeatureCard(
                        icon: "chart.line.uptrend.xyaxis",
                        iconColor: .pink,
                        title: "Task Insights Dashboard",
                        description: "AI-generated insights about your productivity patterns and habits",
                        features: [
                            "Productivity score and trend analysis",
                            "Peak productivity time detection",
                            "Task completion patterns by time of day",
                            "Project health metrics and warnings",
                            "Personalized productivity recommendations",
                            "Streak tracking for motivation"
                        ],
                        howToUse: "Access from Tasks view → AI Tools → Productivity Insights"
                    )
                }
                .padding(.horizontal)
                
                // Tips Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Pro Tips")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ProTipRow(tip: "AI features work best with detailed task descriptions")
                        ProTipRow(tip: "Complete tasks regularly to improve pattern detection accuracy")
                        ProTipRow(tip: "Review AI suggestions before applying them")
                        ProTipRow(tip: "Combine multiple AI features for maximum productivity")
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("AI Features")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AIFeatureCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let features: [String]
    let howToUse: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 40, height: 40)
                    .background(iconColor.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Features
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Features:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(features, id: \.self) { feature in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(iconColor)
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // How to use
                    VStack(alignment: .leading, spacing: 4) {
                        Text("How to use:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(howToUse)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }
    }
}

struct ProTipRow: View {
    let tip: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "lightbulb.fill")
                .font(.caption)
                .foregroundColor(.yellow)
            
            Text(tip)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    NavigationStack {
        AIHelpView()
    }
}
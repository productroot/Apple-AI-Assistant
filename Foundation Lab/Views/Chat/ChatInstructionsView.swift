//
//  InstructionsView.swift
//  FoundationLab
//
//  Created by Assistant on 7/1/25.
//

import SwiftUI

struct ChatInstructionsView: View {
    @Binding var showInstructions: Bool
    @Binding var instructions: String
    @Binding var customInstructions: String
    @Binding var selectedTraits: Set<PersonalityTrait>
    let onApply: () -> Void
    let onReset: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: { showInstructions.toggle() }) {
                HStack(spacing: Spacing.small) {
                    Image(systemName: showInstructions ? "chevron.down" : "chevron.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("Instructions")
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !showInstructions {
                        Text("Customize AI behavior")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)
            }
            .buttonStyle(.plain)
            
            if showInstructions {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Current System Prompt
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Current System Prompt")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            Text(instructions)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(Spacing.small)
                        .frame(maxWidth: .infinity, maxHeight: 100, alignment: .topLeading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, Spacing.medium)
                    
                    // Personality Traits
                    PersonalityTraitsView(selectedTraits: $selectedTraits)
                    
                    // Custom Instructions
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Custom Instructions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, Spacing.medium)
                        
                        ZStack(alignment: .topLeading) {
                            if customInstructions.isEmpty {
                                Text("Add any additional instructions for the AI...")
                                    .font(.body)
                                    .foregroundColor(.secondary.opacity(0.6))
                                    .padding(Spacing.medium)
                                    .allowsHitTesting(false)
                            }
                            
                            TextEditor(text: $customInstructions)
                                .font(.body)
                                .scrollContentBackground(.hidden)
                                .padding(Spacing.small)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 120, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, Spacing.medium)
                    }
                    
                    HStack {
                        Button("Reset") {
                            onReset()
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Text("Changes will apply to new conversations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Apply Now") {
                            onApply()
                            showInstructions = false
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        #if os(iOS) || os(macOS)
                        .buttonStyle(.glassProminent)
                        #else
                        .buttonStyle(.bordered)
                        #endif
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.bottom, Spacing.small)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.regularMaterial)
        .cornerRadius(12)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
    }
}

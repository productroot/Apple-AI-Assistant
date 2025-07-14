//
//  PersonalityTraitsView.swift
//  Foundation Lab
//
//  Created by Assistant on 7/14/25.
//

import SwiftUI

struct PersonalityTraitsView: View {
    @Binding var selectedTraits: Set<PersonalityTrait>
    @State private var showAllTraits = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Personality Traits")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { 
                    withAnimation(.spring(response: 0.3)) {
                        showAllTraits.toggle()
                    }
                }) {
                    Image(systemName: showAllTraits ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, Spacing.medium)
            
            if showAllTraits {
                // Grid layout when expanded - no scrolling needed
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: Spacing.small)
                ], spacing: Spacing.small) {
                    ForEach(PersonalityTrait.allTraits) { trait in
                        PersonalityPillView(
                            trait: trait,
                            isSelected: selectedTraits.contains(trait),
                            action: {
                                withAnimation(.spring(response: 0.3)) {
                                    if selectedTraits.contains(trait) {
                                        selectedTraits.remove(trait)
                                        print("❌ Removed personality trait: \(trait.name)")
                                    } else {
                                        selectedTraits.insert(trait)
                                        print("✅ Added personality trait: \(trait.name)")
                                    }
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, Spacing.medium)
                .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                // Horizontal scroll when collapsed - show all traits
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.small) {
                        ForEach(PersonalityTrait.allTraits) { trait in
                            PersonalityPillView(
                                trait: trait,
                                isSelected: selectedTraits.contains(trait),
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        if selectedTraits.contains(trait) {
                                            selectedTraits.remove(trait)
                                            print("❌ Removed personality trait: \(trait.name)")
                                        } else {
                                            selectedTraits.insert(trait)
                                            print("✅ Added personality trait: \(trait.name)")
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                }
            }
        }
        .padding(.vertical, Spacing.small)
    }
}

struct PersonalityPillView: View {
    let trait: PersonalityTrait
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: trait.icon)
                    .font(.caption2)
                
                Text(trait.name)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? trait.color.color : Color.gray.opacity(0.15))
            )
            .foregroundColor(isSelected ? .white : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

#Preview {
    PersonalityTraitsView(selectedTraits: .constant(Set<PersonalityTrait>()))
        .frame(maxWidth: 600)
        .padding()
}
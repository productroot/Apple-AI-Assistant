import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct QuickAddOverlay: View {
    @Binding var isPresented: Bool
    let onTaskSelected: () -> Void
    let onProjectSelected: () -> Void
    let onAreaSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // New To-Do option
            Button {
                isPresented = false
                onTaskSelected()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "circle")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("New To-Do")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Text("Quickly add a to-do to your inbox.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.leading, 66)
            
            // New Project option
            Button {
                isPresented = false
                onProjectSelected()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Project")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Define a goal, then work towards it one to-do at a time.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            Divider()
                .padding(.leading, 66)
            
            // New Area option
            Button {
                isPresented = false
                onAreaSelected()
            } label: {
                HStack(spacing: 16) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("New Area")
                            .font(.system(size: 16, weight: .medium))
                        
                        Text("Group projects and to-dos based on different responsibilities, such as Family or Work.")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
#if os(iOS)
                .fill(Color(UIColor.systemGray6))
#else
                .fill(Color(NSColor.controlColor))
#endif
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: -5)
        )
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.3)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            QuickAddOverlay(
                isPresented: .constant(true),
                onTaskSelected: { print("Task selected") },
                onProjectSelected: { print("Project selected") },
                onAreaSelected: { print("Area selected") }
            )
            .padding()
        }
    }
}
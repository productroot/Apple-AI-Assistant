import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct InlineProjectCreationView: View {
    @Binding var projectName: String
    @Binding var selectedAreaId: UUID?
    let areas: [Area]
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)
                .padding(.leading, 20)
            
            TextField("New Project", text: $projectName)
                .font(.body)
                .focused($isFocused)
                .onSubmit {
                    if !projectName.isEmpty {
                        onSave()
                    }
                }
            
            HStack(spacing: 8) {
                Button {
                    onCancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                
                Button {
                    if !projectName.isEmpty {
                        onSave()
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(projectName.isEmpty ? .secondary : .accentColor)
                }
                .disabled(projectName.isEmpty)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
#if os(iOS)
        .background(Color(UIColor.secondarySystemBackground))
#else
        .background(Color(NSColor.controlBackgroundColor))
#endif
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    InlineProjectCreationView(
        projectName: .constant(""),
        selectedAreaId: .constant(nil),
        areas: [],
        onSave: { print("Save") },
        onCancel: { print("Cancel") }
    )
    .padding()
}
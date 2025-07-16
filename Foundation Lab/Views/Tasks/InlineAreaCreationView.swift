import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct InlineAreaCreationView: View {
    @Binding var areaName: String
    let onSave: () -> Void
    let onCancel: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 24))
                .foregroundColor(.gray)
                .frame(width: 30)
            
            TextField("New Area", text: $areaName)
                .font(.system(size: 16))
                .focused($isFocused)
                .onSubmit {
                    if !areaName.isEmpty {
                        onSave()
                    }
                }
            
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: onSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(areaName.isEmpty ? .secondary.opacity(0.5) : .accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(areaName.isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
#if os(iOS)
        .background(Color(UIColor.secondarySystemGroupedBackground))
#else
        .background(Color(NSColor.controlBackgroundColor))
#endif
        .cornerRadius(10)
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    VStack {
        InlineAreaCreationView(
            areaName: .constant(""),
            onSave: { print("Save") },
            onCancel: { print("Cancel") }
        )
        .padding()
    }
#if os(iOS)
    .background(Color(UIColor.systemGroupedBackground))
#else
    .background(Color(NSColor.controlBackgroundColor))
#endif
}
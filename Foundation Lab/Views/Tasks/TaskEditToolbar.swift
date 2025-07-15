import SwiftUI

struct TaskEditToolbar: View {
    let task: TodoTask
    let viewModel: TasksViewModel
    let onMoveRequested: () -> Void
    let onDeleteRequested: () -> Void
    let onDuplicateRequested: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Move Button
            Button {
                onMoveRequested()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                    Text("Move")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 40)
            
            // Delete Button
            Button {
                onDeleteRequested()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.title3)
                    Text("Delete")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 40)
            
            // More Button
            Menu {
                Button("Duplicate") {
                    onDuplicateRequested()
                }
                Button("Copy Link") {
                    // TODO: Implement copy link
                }
                Button("Share") {
                    // TODO: Implement share
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "ellipsis")
                        .font(.title3)
                    Text("More")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

#Preview {
    TaskEditToolbar(
        task: TodoTask(title: "Sample Task"),
        viewModel: TasksViewModel.shared,
        onMoveRequested: {},
        onDeleteRequested: {},
        onDuplicateRequested: {}
    )
} 
//
//  ChecklistEditView.swift
//  FoundationLab
//
//  Created by Assistant on 7/14/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ChecklistEditView: View {
    @Binding var checklistItems: [ChecklistItem]
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    
    @State private var editingItem: ChecklistItem?
    @State private var newItemText = ""
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ChecklistItem?
    @FocusState private var isNewItemFocused: Bool
    @FocusState private var isEditingFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with progress
                if !checklistItems.isEmpty {
                    HStack {
                        Text("Checklist Items")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(checklistItems.filter { $0.isCompleted }.count)/\(checklistItems.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.systemGray5))
                            .cornerRadius(8)
                    }
                    .padding()
                }
                
                // Checklist items
                List {
                    ForEach(checklistItems, id: \.id) { item in
                        ChecklistEditRow(
                            item: Binding(
                                get: { item },
                                set: { newValue in
                                    if let index = checklistItems.firstIndex(where: { $0.id == item.id }) {
                                        checklistItems[index] = newValue
                                    }
                                }
                            ),
                            onDelete: {
                                itemToDelete = item
                                showingDeleteAlert = true
                            }
                        )
                    }
                    .onMove { from, to in
                        withAnimation {
                            checklistItems.move(fromOffsets: from, toOffset: to)
                            print("📝 Moved checklist item from \(from) to \(to)")
                        }
                    }
                    .onDelete { indexSet in
                        // Handle swipe-to-delete
                        for index in indexSet {
                            if index < checklistItems.count {
                                itemToDelete = checklistItems[index]
                                showingDeleteAlert = true
                            }
                        }
                    }
                    
                    // Add new item row
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                        
                        TextField("Add checklist item", text: $newItemText)
                            .textFieldStyle(.plain)
                            .focused($isNewItemFocused)
                            .onSubmit {
                                addNewItem()
                            }
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
            }
            .navigationTitle("Edit Checklist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Item", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let itemToDelete = itemToDelete {
                        withAnimation {
                            checklistItems.removeAll { $0.id == itemToDelete.id }
                            print("🗑️ Deleted checklist item: \(itemToDelete.title)")
                        }
                    }
                }
            } message: {
                if let itemToDelete = itemToDelete {
                    Text("Are you sure you want to delete \"\(itemToDelete.title)\"?")
                }
            }
        }
    }
    
    private func addNewItem() {
        let trimmedText = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newItem = ChecklistItem(title: trimmedText)
        withAnimation {
            checklistItems.append(newItem)
            print("➕ Added new checklist item: \(trimmedText)")
        }
        newItemText = ""
    }
}

// MARK: - Checklist Edit Row
struct ChecklistEditRow: View {
    @Binding var item: ChecklistItem
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle (always visible)
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.tertiary)
                        .frame(width: 16, height: 3)
                }
            }
            .frame(width: 20)
            
            // Completion toggle
            Button {
                item.isCompleted.toggle()
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                    .contentTransition(.symbolEffect)
            }
            .buttonStyle(.plain)
            
            // Item title
            if isEditing {
                TextField("Item", text: $item.title)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit {
                        isEditing = false
                    }
                    .onChange(of: isFocused) { _, newValue in
                        if !newValue {
                            isEditing = false
                        }
                    }
            } else {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isEditing = true
                        isFocused = true
                    }
            }
            
            // Delete button (always visible with trash icon)
            Button {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.title3)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ChecklistEditView(
        checklistItems: .constant([
            ChecklistItem(title: "First item"),
            ChecklistItem(title: "Second item", isCompleted: true),
            ChecklistItem(title: "Third item")
        ]),
        onSave: {}
    )
}
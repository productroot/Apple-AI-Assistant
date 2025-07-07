import SwiftUI

struct AddItemTypeSelectionView: View {
    @Binding var isPresented: Bool
    @Binding var selectedType: TaskItemType?
    
    enum TaskItemType {
        case task
        case project
        case area
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("What would you like to create?")
                    .font(.headline)
                    .padding(.top)
                
                VStack(spacing: 12) {
                    Button {
                        selectedType = .task
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Task")
                                    .font(.headline)
                                Text("A single to-do item")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        selectedType = .project
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "folder")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Project")
                                    .font(.headline)
                                Text("A collection of related tasks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button {
                        selectedType = .area
                        isPresented = false
                    } label: {
                        HStack {
                            Image(systemName: "square.stack.3d.up")
                                .font(.title2)
                                .foregroundColor(.green)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Area")
                                    .font(.headline)
                                Text("A category for organizing tasks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    AddItemTypeSelectionView(
        isPresented: .constant(true),
        selectedType: .constant(nil)
    )
}
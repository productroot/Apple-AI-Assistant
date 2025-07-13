//
//  ChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct ChatView: View {
    @Binding var viewModel: ChatViewModel
    @State private var scrollID: String?
    @State private var messageText = ""
    @State private var showInstructions = false
    @State private var showFeedbackSheet = false
    @State private var selectedEntryForFeedback: Transcript.Entry?
    @State private var selectedContext: ChatContext?
    @FocusState private var isTextFieldFocused: Bool
    
    enum ChatContext: String, CaseIterable {
        case calendar = "Calendar"
        case reminders = "Reminders"
        
        var icon: String {
            switch self {
            case .calendar: return "calendar"
            case .reminders: return "checklist"
            }
        }
        
        var description: String {
            switch self {
            case .calendar: return "Access calendar events"
            case .reminders: return "Access and manage reminders"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesView
                .contentShape(Rectangle())
                .onTapGesture {
                    isTextFieldFocused = false
                }
            
            // Context Pills
            if !viewModel.isLoading {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ChatContext.allCases, id: \.self) { context in
                            Button {
                                if selectedContext == context {
                                    selectedContext = nil
                                    switch context {
                                    case .calendar:
                                        viewModel.removeCalendarContext()
                                    case .reminders:
                                        viewModel.removeRemindersContext()
                                    }
                                } else {
                                    selectedContext = context
                                    switch context {
                                    case .calendar:
                                        viewModel.updateCalendarContext()
                                    case .reminders:
                                        viewModel.updateRemindersContext()
                                    }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: context.icon)
                                        .font(.caption)
                                    Text(context.rawValue)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedContext == context ? Color.blue : Color.secondary.opacity(0.2))
                                .foregroundColor(selectedContext == context ? .white : .primary)
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(UIColor.systemBackground))
            }

            ChatInputView(
                messageText: $messageText,
                isTextFieldFocused: $isTextFieldFocused
            )
        }
        .safeAreaInset(edge: .top) {
            instructionsView
        }
        .environment(viewModel)
        .navigationTitle("Chat")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: { showFeedbackSheet = true }) {
                    Label("Feedback", systemImage: "bubble.left.and.exclamationmark.bubble.right")
                }
                .disabled(viewModel.session.transcript.isEmpty)
                .help("Provide feedback on responses")

                Button("Clear") {
                    viewModel.clearChat()
                }
                .disabled(viewModel.session.transcript.isEmpty)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .onAppear {
            // Auto-focus when chat appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackView(
                viewModel: viewModel,
                selectedEntry: $selectedEntryForFeedback,
                isPresented: $showFeedbackSheet
            )
#if os(macOS)
            .frame(minWidth: 600, minHeight: 400)
#endif
        }
    }


    // MARK: - View Components

    private var instructionsView: some View {
        ChatInstructionsView(
            showInstructions: $showInstructions,
            instructions: $viewModel.instructions,
            onApply: {
                viewModel.updateInstructions(viewModel.instructions)
                viewModel.clearChat()
            }
        )
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(viewModel.session.transcript) { entry in
                        TranscriptEntryView(entry: entry)
                            .id(entry.id)
                    }

                    if viewModel.isSummarizing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Summarizing conversation...")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("summarizing")
                    }

                    // Empty spacer for bottom padding
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
#if os(iOS)
            .scrollDismissesKeyboard(.interactively)
#endif
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.session.transcript.count) { _, _ in
                if let lastEntry = viewModel.session.transcript.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastEntry.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: viewModel.isSummarizing) { _, isSummarizing in
                if isSummarizing {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("summarizing", anchor: .bottom)
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }
}

#Preview {
    ChatView(viewModel: .constant(ChatViewModel()))
}

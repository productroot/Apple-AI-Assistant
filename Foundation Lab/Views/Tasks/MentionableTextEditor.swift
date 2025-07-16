import SwiftUI
import Contacts
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct MentionableTextEditor: View {
    @Binding var text: String
    @Binding var mentionedContacts: [CNContact]
    let placeholder: String
    
    @State private var showingSuggestions = false
    @State private var currentMention: MentionDetector.Mention?
    @State private var cursorPosition: Int = 0
    @State private var mentionTokens: [MentionToken] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    detectMentions(in: newValue)
                }
#if os(iOS)
                .onReceive(NotificationCenter.default.publisher(for: UITextView.textDidChangeNotification)) { _ in
                    updateCursorPosition()
                }
#endif
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }
            
            if showingSuggestions, let mention = currentMention {
                GeometryReader { geometry in
                    ContactSuggestionView(
                        searchText: mention.searchText,
                        onSelect: { contact in
                            insertContact(contact, replacing: mention)
                        },
                        onDismiss: {
                            showingSuggestions = false
                        }
                    )
                    .frame(width: 250)
                    .offset(x: 10, y: 30)
                }
            }
        }
    }
    
    private func detectMentions(in text: String) {
        // Check if we're currently typing a mention
        if let mention = MentionDetector.getCurrentMention(in: text, at: cursorPosition) {
            // Don't show suggestions if this mention is already a token
            let isExistingToken = mentionTokens.contains { token in
                text.contains(token.placeholder)
            }
            
            if !isExistingToken {
                currentMention = mention
                showingSuggestions = true
                print("🔍 Detected mention: \(mention.text) at position \(mention.range.location)")
            }
        } else {
            showingSuggestions = false
            currentMention = nil
        }
    }
    
    private func updateCursorPosition() {
        // This would need proper implementation to track cursor position
    }
    
    private func insertContact(_ contact: CNContact, replacing mention: MentionDetector.Mention) {
        // Create a mention token
        let token = MentionToken(contact: contact)
        
        // Replace the @mention with the token placeholder
        text = MentionDetector.replaceMention(in: text, mention: mention, with: token.placeholder + " ")
        
        // Track the token
        mentionTokens.append(token)
        
        // Add to mentioned contacts if not already present
        if !mentionedContacts.contains(where: { $0.identifier == contact.identifier }) {
            mentionedContacts.append(contact)
            print("✅ Added contact to mentions: \(token.displayName)")
        }
        
        showingSuggestions = false
        currentMention = nil
    }
}

struct MentionableTextField: View {
    @Binding var text: String
    @Binding var mentionedContacts: [CNContact]
    let placeholder: String
    
    @State private var showingSuggestions = false
    @State private var currentMention: MentionDetector.Mention?
    @State private var mentionTokens: [MentionToken] = []
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .onChange(of: text) { oldValue, newValue in
                    detectMentions(in: newValue)
                }
            
            if showingSuggestions, let mention = currentMention {
                ContactSuggestionView(
                    searchText: mention.searchText,
                    onSelect: { contact in
                        insertContact(contact, replacing: mention)
                    },
                    onDismiss: {
                        showingSuggestions = false
                    }
                )
                .frame(width: 250)
                .offset(x: 0, y: 30)
            }
        }
    }
    
    private func detectMentions(in text: String) {
        if let mention = MentionDetector.getCurrentMention(in: text, at: text.count) {
            // Don't show suggestions if this mention is already a token
            let isExistingToken = mentionTokens.contains { token in
                text.contains(token.placeholder)
            }
            
            if !isExistingToken {
                currentMention = mention
                showingSuggestions = true
                print("🔍 Detected mention in TextField: \(mention.text)")
            }
        } else {
            showingSuggestions = false
            currentMention = nil
        }
    }
    
    private func insertContact(_ contact: CNContact, replacing mention: MentionDetector.Mention) {
        // Create a mention token
        let token = MentionToken(contact: contact)
        
        // Replace the @mention with the token placeholder
        text = MentionDetector.replaceMention(in: text, mention: mention, with: token.placeholder + " ")
        
        // Track the token
        mentionTokens.append(token)
        
        // Add to mentioned contacts if not already present
        if !mentionedContacts.contains(where: { $0.identifier == contact.identifier }) {
            mentionedContacts.append(contact)
            print("✅ Added contact to mentions: \(token.displayName)")
        }
        
        showingSuggestions = false
        currentMention = nil
    }
}
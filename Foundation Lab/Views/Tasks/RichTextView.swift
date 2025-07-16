import SwiftUI
import Contacts

struct RichTextView: View {
    let text: String
    let mentionedContacts: [CNContact]
    let mentionTokens: [MentionToken]
    
    init(text: String, mentionedContacts: [CNContact]) {
        self.text = text
        self.mentionedContacts = mentionedContacts
        
        // Parse text to find mention tokens
        var tokens: [MentionToken] = []
        for contact in mentionedContacts {
            let token = MentionToken(contact: contact)
            if text.contains(token.placeholder) {
                tokens.append(token)
            }
        }
        self.mentionTokens = tokens
    }
    
    var body: some View {
        // Split text by mentions and create appropriate views
        textWithPills()
    }
    
    @ViewBuilder
    private func textWithPills() -> some View {
        // If no mentions, just show plain text
        if mentionTokens.isEmpty {
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Create a flow layout with text and pills
            ContactFlowLayout(spacing: 4) {
                let components = parseTextComponents()
                ForEach(Array(components.enumerated()), id: \.offset) { _, component in
                    switch component {
                    case .text(let string):
                        Text(string)
                            .fixedSize(horizontal: false, vertical: true)
                    case .contact(let contact):
                        ContactPill(contact: contact)
                    }
                }
            }
        }
    }
    
    private enum TextComponent {
        case text(String)
        case contact(CNContact)
    }
    
    private func parseTextComponents() -> [TextComponent] {
        var components: [TextComponent] = []
        var currentText = text
        
        // Sort tokens by their appearance in text
        let sortedTokens = mentionTokens.sorted { token1, token2 in
            let range1 = (currentText as NSString).range(of: token1.placeholder)
            let range2 = (currentText as NSString).range(of: token2.placeholder)
            return range1.location < range2.location
        }
        
        for token in sortedTokens {
            if let contact = mentionedContacts.first(where: { $0.identifier == token.contactId }) {
                let range = (currentText as NSString).range(of: token.placeholder)
                if range.location != NSNotFound {
                    // Add text before the mention
                    if range.location > 0 {
                        let beforeText = (currentText as NSString).substring(to: range.location)
                        if !beforeText.isEmpty {
                            components.append(.text(beforeText))
                        }
                    }
                    
                    // Add the contact pill
                    components.append(.contact(contact))
                    
                    // Update current text to remaining portion
                    let afterLocation = range.location + range.length
                    if afterLocation < currentText.count {
                        currentText = (currentText as NSString).substring(from: afterLocation)
                    } else {
                        currentText = ""
                    }
                }
            }
        }
        
        // Add any remaining text
        if !currentText.isEmpty {
            components.append(.text(currentText))
        }
        
        return components
    }
}

// Simple flow layout for mixing text and pills
struct ContactFlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                    y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > width && currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: width, height: currentY + lineHeight)
        }
    }
}
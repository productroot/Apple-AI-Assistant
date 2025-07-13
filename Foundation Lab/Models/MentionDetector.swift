import Foundation

struct MentionDetector {
    struct Mention {
        let range: NSRange
        let text: String
        var searchText: String {
            String(text.dropFirst())
        }
    }
    
    static func detectMentions(in text: String) -> [Mention] {
        let pattern = "@[A-Za-z0-9]*"
        var mentions: [Mention] = []
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsText = text as NSString
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
            
            for match in matches {
                let mentionText = nsText.substring(with: match.range)
                mentions.append(Mention(range: match.range, text: mentionText))
            }
        } catch {
            print("❌ Error detecting mentions: \(error)")
        }
        
        return mentions
    }
    
    static func getCurrentMention(in text: String, at cursorPosition: Int) -> Mention? {
        let mentions = detectMentions(in: text)
        
        for mention in mentions {
            let mentionEndPosition = mention.range.location + mention.range.length
            if cursorPosition >= mention.range.location && cursorPosition <= mentionEndPosition {
                return mention
            }
        }
        
        return nil
    }
    
    static func replaceMention(in text: String, mention: Mention, with replacement: String) -> String {
        let nsText = text as NSString
        return nsText.replacingCharacters(in: mention.range, with: replacement)
    }
}
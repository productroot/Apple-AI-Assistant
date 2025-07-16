import Foundation
import Contacts

struct MentionToken: Identifiable, Codable, Hashable {
    var id: UUID
    let contactId: String
    let displayName: String
    let placeholder: String // The text that will be shown in the text field (e.g., "@John")
    
    init(contact: CNContact) {
        self.id = UUID()
        self.contactId = contact.identifier
        self.displayName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        self.placeholder = "@\(contact.givenName)"
    }
}
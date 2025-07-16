import SwiftUI
import Contacts
#if os(iOS)
import UIKit
#else
import AppKit
#endif

struct ContactSuggestionView: View {
    let searchText: String
    let onSelect: (CNContact) -> Void
    let onDismiss: () -> Void
    
    @State private var contacts: [CNContact] = []
    @State private var isSearching = false
    
    var body: some View {
        VStack(spacing: 0) {
            if isSearching {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Searching contacts...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else if contacts.isEmpty {
                Text("No contacts found")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(contacts, id: \.identifier) { contact in
                            ContactRow(contact: contact) {
                                onSelect(contact)
                            }
                            
                            if contact != contacts.last {
                                Divider()
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(8)
        .shadow(radius: 4)
        .onAppear {
            searchContacts()
        }
        .onChange(of: searchText) {
            searchContacts()
        }
    }
    
    private func searchContacts() {
        guard !searchText.isEmpty else {
            contacts = []
            return
        }
        
        isSearching = true
        
        Task {
            do {
                let store = CNContactStore()
                let keysToFetch = [
                    CNContactGivenNameKey,
                    CNContactFamilyNameKey,
                    CNContactEmailAddressesKey,
                    CNContactPhoneNumbersKey,
                    CNContactImageDataKey,
                    CNContactOrganizationNameKey
                ] as [CNKeyDescriptor]
                
                let predicate = CNContact.predicateForContacts(matchingName: searchText)
                let fetchedContacts = try store.unifiedContacts(matching: predicate, keysToFetch: keysToFetch)
                
                await MainActor.run {
                    contacts = Array(fetchedContacts.prefix(5))
                    isSearching = false
                    print("📱 Found \(contacts.count) contacts matching '\(searchText)'")
                }
            } catch {
                print("❌ Error searching contacts: \(error)")
                await MainActor.run {
                    contacts = []
                    isSearching = false
                }
            }
        }
    }
}

struct ContactRow: View {
    let contact: CNContact
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if let imageData = contact.imageData {
#if os(iOS)
                    if let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
#else
                    if let image = NSImage(data: imageData) {
                        Image(nsImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    }
#endif
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.gray)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(contact.givenName) \(contact.familyName)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    
                    if let email = contact.emailAddresses.first?.value as String? {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let phone = contact.phoneNumbers.first?.value.stringValue {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(UIColor.secondarySystemBackground))
        .hoverEffect()
    }
}
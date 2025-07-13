import SwiftUI
import Contacts

struct InteractiveContactView: View {
    let contact: CNContact
    var style: ContactViewStyle = .default
    @State private var showingContactDetails = false
    
    enum ContactViewStyle {
        case `default`
        case compact
        case mention
    }
    
    var body: some View {
        Button(action: {
            showingContactDetails = true
        }) {
            switch style {
            case .default:
                defaultView
            case .compact:
                compactView
            case .mention:
                mentionView
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingContactDetails) {
            ContactDetailView(contact: contact)
        }
    }
    
    private var defaultView: some View {
        HStack(spacing: 4) {
            contactImage(size: 16)
            
            Text("\(contact.givenName) \(contact.familyName)")
                .font(.system(size: 14))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(4)
    }
    
    private var compactView: some View {
        HStack(spacing: 6) {
            contactImage(size: 20)
            
            Text("\(contact.givenName) \(contact.familyName)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    private var mentionView: some View {
        HStack(spacing: 3) {
            Text("@")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue.opacity(0.8))
            
            contactImage(size: 14)
            
            Text(contact.givenName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func contactImage(size: CGFloat) -> some View {
        Group {
            if let imageData = contact.imageData,
               let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: size))
                    .foregroundColor(style == .mention ? .blue : .gray)
            }
        }
    }
}

struct ContactDetailView: View {
    let contact: CNContact
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        if let imageData = contact.imageData,
                           let image = UIImage(data: imageData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("\(contact.givenName) \(contact.familyName)")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if !contact.organizationName.isEmpty {
                                Text(contact.organizationName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                if !contact.phoneNumbers.isEmpty {
                    Section("Phone Numbers") {
                        ForEach(contact.phoneNumbers, id: \.identifier) { phoneNumber in
                            HStack {
                                Text(CNLabeledValue<NSString>.localizedString(forLabel: phoneNumber.label ?? ""))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(phoneNumber.value.stringValue)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
                
                if !contact.emailAddresses.isEmpty {
                    Section("Email Addresses") {
                        ForEach(contact.emailAddresses, id: \.identifier) { email in
                            HStack {
                                Text(CNLabeledValue<NSString>.localizedString(forLabel: email.label ?? ""))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(email.value as String)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Contact Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
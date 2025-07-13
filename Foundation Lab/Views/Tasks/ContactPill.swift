import SwiftUI
import Contacts

struct ContactPill: View {
    let contact: CNContact
    @State private var showingContactDetails = false
    
    var body: some View {
        Button(action: {
            showingContactDetails = true
        }) {
            HStack(spacing: 3) {
                // Contact image
                if let imageData = contact.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 16)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                
                // Contact name
                Text(contact.givenName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.blue)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingContactDetails) {
            ContactDetailView(contact: contact)
        }
    }
}
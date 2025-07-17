import SwiftUI

struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button {
            print("🎯 FloatingActionButton tapped - triggering action")
            action()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(Color.accentColor.opacity(0.8))
            .clipShape(Circle())
            .glassEffect()
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .phaseAnimator([false, true]) { content, phase in
            content
                .offset(y: phase ? -3 : 3)
                .scaleEffect(phase ? 1.02 : 0.98)
        } animation: { phase in
            .easeInOut(duration: 3.0)
        }
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingActionButton {
                    print("Action triggered")
                }
                .padding()
            }
        }
    }
}
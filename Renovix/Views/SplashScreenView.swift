import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var logoScale = 0.5
    @State private var logoOpacity = 0.0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity = 0.0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemTeal).opacity(0.1),
                    Color(.systemBackground)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()
                
                Text("Renovix")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("Your AR Furniture Companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .offset(y: textOffset)
                    .opacity(textOpacity)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textOffset = 0
                textOpacity = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    isActive = true
                }
            }
        }
        .fullScreenCover(isPresented: $isActive) {
            OnboardingView()
        }
    }
}

#Preview {
    SplashScreenView()
} 

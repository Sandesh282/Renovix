import SwiftUI

struct OnboardingView: View {
    @State private var selection = 0
    @Environment(\.dismiss) var dismiss
    @State private var showHome = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.1), Color(.systemBackground)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                VStack {
                    TabView(selection: $selection) {
                        OnboardingPageView(
                            title: "View & Experience",
                            subtitle: "Visualize furniture in your space with augmented reality.",
                            icon: "arkit"
                        ).tag(0)
                        OnboardingPageView(
                            title: "Design Your Space",
                            subtitle: "Create the perfect layout for your home instantly.",
                            icon: "square.3.stack.3d"
                        ).tag(1)
                        OnboardingPageView(
                            title: "Explore Collection",
                            subtitle: "Browse our premium selection of modern furniture.",
                            icon: "sofa"
                        ).tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                    .animation(.easeInOut, value: selection)
                    .frame(height: 550)

                    if selection == 2 {
                        Button(action: { showHome = true }) {
                            HStack {
                                Text("Get Started")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(16)
                            .shadow(radius: 5)
                            .padding(.horizontal, 32)
                        }
                        .padding(.top, 24)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                
                if selection < 2 {
                    Button(action: {
                        withAnimation { selection = 2 }
                    }) {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                            .padding(.trailing, 24)
                            .contentShape(Rectangle()) 
                    }
                    .zIndex(1)
                }
            }
            .navigationDestination(isPresented: $showHome) {
                HomeView()
            }
        }
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let icon: String
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)
                .padding()
                .background(Color.white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(radius: 8)
            Text(title)
                .font(.title).bold()
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    OnboardingView()
} 
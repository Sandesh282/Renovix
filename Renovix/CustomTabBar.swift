
import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(tab: .home, selectedTab: $selectedTab, icon: "house.fill")
            Spacer(minLength: 0)
            TabBarItem(tab: .cart, selectedTab: $selectedTab, icon: "cart")
            Spacer(minLength: 0)
            TabBarItem(tab: .profile, selectedTab: $selectedTab, icon: "person")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        )
        .frame(maxWidth: 280) 
        .padding(.bottom, 8) 
    }
}

enum Tab {
    case home, cart, profile
}

struct TabBarItem: View {
    let tab: Tab
    @Binding var selectedTab: Tab
    let icon: String

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 24)) 
                .foregroundColor(selectedTab == tab ? .black : .gray.opacity(0.5))
                .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    StatefulPreviewWrapper(.home) { CustomTabBar(selectedTab: $0) }
}

// MARK: - Preview Helper
struct StatefulPreviewWrapper<T: Hashable & Equatable, Content: View>: View {
    @State private var value: T
    var content: (Binding<T>) -> Content

    init(_ initialValue: T, content: @escaping (Binding<T>) -> Content) {
        self._value = State(initialValue: initialValue)
        self.content = content
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.2).ignoresSafeArea()
            VStack {
                Spacer()
                content($value)
            }
        }
    }
}

import SwiftUI

struct ProfileView: View {
    @State private var notificationsEnabled = true
    @State private var darkModeEnabled = false
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // MARK: - Profile Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.4)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .overlay(
                        Circle()
                            .stroke(.ultraThinMaterial, lineWidth: 4)
                    )
                    
                    VStack(spacing: 4) {
                        Text("Guest User")
                            .font(.title2.bold())
                        Text("Sign in to sync your data")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {}) {
                        Text("Sign In")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(24)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 8)
                
                // MARK: - Stats Row
                HStack(spacing: 0) {
                    StatItem(value: "3", label: "Orders")
                    Divider().frame(height: 40)
                    StatItem(value: "5", label: "Wishlist")
                    Divider().frame(height: 40)
                    StatItem(value: "2", label: "Reviews")
                }
                .padding(.vertical, 20)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // MARK: - Settings Sections
                VStack(spacing: 12) {
                    SettingsSection(title: "Account") {
                        SettingsRow(icon: "person.circle", title: "Edit Profile", showChevron: true)
                        SettingsRow(icon: "location", title: "Addresses", showChevron: true)
                        SettingsRow(icon: "creditcard", title: "Payment Methods", showChevron: true)
                    }
                    
                    SettingsSection(title: "Preferences") {
                        SettingsToggleRow(icon: "bell", title: "Notifications", isOn: $notificationsEnabled)
                        SettingsToggleRow(icon: "moon", title: "Dark Mode", isOn: $darkModeEnabled)
                        SettingsRow(icon: "globe", title: "Language", value: "English", showChevron: true)
                    }
                    
                    SettingsSection(title: "Support") {
                        SettingsRow(icon: "questionmark.circle", title: "Help Center", showChevron: true)
                        SettingsRow(icon: "envelope", title: "Contact Us", showChevron: true)
                        SettingsRow(icon: "doc.text", title: "Terms & Privacy", showChevron: true)
                    }
                }
                .padding(.horizontal, 20)
                
                // MARK: - App Info
                VStack(spacing: 8) {
                    Text("Renovix")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                .padding(.bottom, 120)
            }
        }
        .background(Color(.systemBackground))
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    var value: String? = nil
    var showChevron: Bool = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
                    .frame(width: 28)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 28)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

#Preview {
    ProfileView()
}

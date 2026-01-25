import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    
    var body: some View {
        List {
            // Profile Header Section
            Section {
                HStack(spacing: 14) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 60, height: 60)
                        
                        if let imageURL = viewModel.user?.profileImageURL {
                            AsyncImageView(url: imageURL)
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else {
                            Text(viewModel.user?.fullName.prefix(1).uppercased() ?? "?")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.user?.fullName ?? "Guest")
                            .font(.headline)
                        
                        Text(viewModel.user?.email ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    showEditProfile = true
                }
            }
            
            // Account Section
            Section {
                NavigationLink {
                    AddressListView(viewModel: viewModel)
                } label: {
                    SettingsRow(
                        icon: "location.fill",
                        iconColor: .blue,
                        title: "Saved Addresses"
                    )
                }
                
                NavigationLink {
                    PaymentMethodsView(viewModel: viewModel)
                } label: {
                    SettingsRow(
                        icon: "creditcard.fill",
                        iconColor: .green,
                        title: "Payment Methods"
                    )
                }
                
                NavigationLink {
                    NotificationsView()
                } label: {
                    SettingsRow(
                        icon: "bell.fill",
                        iconColor: .red,
                        title: "Notifications",
                        badge: viewModel.unreadNotificationCount > 0 ? "\(viewModel.unreadNotificationCount)" : nil
                    )
                }
            }
            
            // Preferences Section
            Section {
                NavigationLink {
                    SettingsView(viewModel: viewModel)
                } label: {
                    SettingsRow(
                        icon: "gearshape.fill",
                        iconColor: .gray,
                        title: "Settings"
                    )
                }
                
                NavigationLink {
                    // Help view
                    Text("Help & Support")
                        .navigationTitle("Help & Support")
                } label: {
                    SettingsRow(
                        icon: "questionmark.circle.fill",
                        iconColor: .purple,
                        title: "Help & Support"
                    )
                }
                
                NavigationLink {
                    // Terms view
                    Text("Terms & Privacy")
                        .navigationTitle("Terms & Privacy")
                } label: {
                    SettingsRow(
                        icon: "doc.text.fill",
                        iconColor: .gray,
                        title: "Terms & Privacy"
                    )
                }
            }
            
            // App Section
            Section {
                Button {
                    // Open app store
                } label: {
                    SettingsRow(
                        icon: "star.fill",
                        iconColor: .orange,
                        title: "Rate MunchlyEats"
                    )
                }
                
                Button {
                    // Share app
                } label: {
                    SettingsRow(
                        icon: "square.and.arrow.up.fill",
                        iconColor: .blue,
                        title: "Share App"
                    )
                }
            }
            
            // Sign Out Section
            Section {
                Button {
                    showSignOutAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
            
            // Version Info
            Section {
                HStack {
                    Spacer()
                    Text("Version 1.0.0")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                CartToolbarButton()
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(viewModel: viewModel)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                viewModel.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var badge: String? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(iconColor)
                .cornerRadius(6)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            if let badge = badge {
                Text(badge)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Profile Menu Row (for NavigationLink) - kept for compatibility
struct ProfileMenuRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    
    var body: some View {
        SettingsRow(icon: icon, iconColor: iconColor, title: title, badge: badge)
    }
}

// MARK: - Profile Section - kept for compatibility
struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Profile Menu Item - kept for compatibility
struct ProfileMenuItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            SettingsRow(icon: icon, iconColor: iconColor, title: title, badge: badge)
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Full Name", text: $viewModel.editFullName)
                    TextField("Phone Number", text: $viewModel.editPhoneNumber)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    HStack {
                        Text("Email")
                        Spacer()
                        Text(viewModel.user?.email ?? "")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.updateProfile()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @State private var showDeleteAlert = false
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $viewModel.notificationsEnabled)
                Toggle("Order Updates", isOn: $viewModel.orderUpdates)
                Toggle("Promotional Offers", isOn: $viewModel.promotionalNotifications)
            }
            
            Section("Location") {
                Toggle("Location Services", isOn: $viewModel.locationEnabled)
            }
            
            Section("Account") {
                Button("Delete Account") {
                    showDeleteAlert = true
                }
                .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

#Preview {
    ProfileView()
}

//
//  SettingsView.swift
//  BookVocab
//
//  Settings and profile management screen.
//  Provides access to account settings, password management, and app preferences.
//
//  Features:
//  - User profile display
//  - Change password option
//  - Sign out functionality
//  - App info and version
//

import SwiftUI

/// Main settings view displaying account options and app settings.
struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    // MARK: - State
    
    /// Shows the change password sheet
    @State private var showChangePassword: Bool = false
    
    /// Shows sign out confirmation
    @State private var showSignOutConfirmation: Bool = false
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Profile header
                        profileHeader
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : -10)
                        
                        // Account section
                        accountSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                        
                        // App section
                        appSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                        
                        // Danger zone
                        dangerZoneSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                        
                        // App version
                        appVersion
                            .padding(.top, AppSpacing.lg)
                        
                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                    .padding(.top, AppSpacing.lg)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                withAnimation(AppAnimation.spring.delay(0.1)) {
                    hasAppeared = true
                }
            }
            // Change password sheet
            .sheet(isPresented: $showChangePassword) {
                ChangePasswordView()
                    .environmentObject(session)
                    .environmentObject(networkMonitor)
            }
            // Sign out confirmation
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await session.signOut()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppColors.tanDark)
                    .frame(width: 80, height: 80)
                
                Text(userInitial)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(AppColors.primary)
            }
            
            // User email
            if let email = session.currentUser?.email {
                Text(email)
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
            }
            
            // Account status
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)
                Text("Signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: 0, y: AppShadow.card.y)
        )
    }
    
    /// User initial for avatar
    private var userInitial: String {
        guard let email = session.currentUser?.email,
              let first = email.first else {
            return "?"
        }
        return String(first).uppercased()
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Account")
            
            VStack(spacing: 0) {
                // Change password
                settingsRow(
                    icon: "key.fill",
                    iconColor: AppColors.primary,
                    title: "Change Password",
                    subtitle: "Update your password"
                ) {
                    showChangePassword = true
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Email (non-editable, just display)
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(Color.blue.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "envelope.fill")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                        
                        Text(session.currentUser?.email ?? "Not available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Email is not editable indicator
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(AppSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
        }
    }
    
    // MARK: - App Section
    
    private var appSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("App")
            
            VStack(spacing: 0) {
                // Premium status (placeholder for future)
                settingsRow(
                    icon: "star.fill",
                    iconColor: .orange,
                    title: "Premium",
                    subtitle: "Upgrade to remove ads"
                ) {
                    // TODO: Show premium upgrade sheet
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Offline status
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(networkMonitor.isConnected ? AppColors.success.opacity(0.15) : Color.orange.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                            .font(.subheadline)
                            .foregroundStyle(networkMonitor.isConnected ? AppColors.success : .orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Network Status")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                        
                        Text(networkMonitor.isConnected ? "Connected" : "Offline mode")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(AppSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
        }
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Session")
            
            Button {
                showSignOutConfirmation = true
            } label: {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(AppColors.error.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.error)
                    }
                    
                    Text("Sign Out")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.error)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.cardBackground)
                )
            }
        }
    }
    
    // MARK: - App Version
    
    private var appVersion: some View {
        VStack(spacing: AppSpacing.xxs) {
            Text("Book Vocab")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Text("Version \(appVersionString)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    /// App version string from bundle
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    // MARK: - Helper Views
    
    /// Section header
    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.leading, AppSpacing.xs)
    }
    
    /// Reusable settings row
    private func settingsRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundStyle(iconColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(NetworkMonitor.shared)
}


//
//  SettingsView.swift
//  BookVocab
//
//  Settings and profile management screen.
//  Provides access to account settings, password management, and app preferences.
//
//  Features:
//  - User profile display and editing
//  - Change password option
//  - Sign out functionality
//  - Notification settings
//  - Study mode preferences
//  - App info and version
//

import SwiftUI
import os.log

/// Logger for SettingsView
private let logger = Logger(subsystem: "com.bookvocab.app", category: "SettingsView")

/// Main settings view displaying account options and app settings.
struct SettingsView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - State
    
    /// Shows the change password sheet
    @State private var showChangePassword: Bool = false
    
    /// Shows sign out confirmation
    @State private var showSignOutConfirmation: Bool = false
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    /// Shows the upgrade modal
    @State private var showUpgradeModal: Bool = false
    
    /// Shows the edit display name alert
    @State private var showEditDisplayName: Bool = false
    
    /// Temporary display name for editing
    @State private var editingDisplayName: String = ""
    
    /// Notifications enabled state (synced with settings)
    @State private var notificationsEnabled: Bool = true
    
    /// Selected study mode preference
    @State private var preferredStudyMode: String = "flashcards"
    
    /// Daily reminder time
    @State private var dailyReminderTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Shows error alert
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    /// Loading states
    @State private var isSavingDisplayName: Bool = false
    @State private var isSavingSettings: Bool = false
    
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
                        
                        // Stats section
                        statsSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                        
                        // Account section
                        accountSection
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 10)
                        
                        // Preferences section
                        preferencesSection
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
                loadSettingsFromSession()
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
            // Upgrade modal
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeView(reason: .generic)
            }
            // Edit display name alert
            .alert("Edit Display Name", isPresented: $showEditDisplayName) {
                TextField("Display Name", text: $editingDisplayName)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    saveDisplayName()
                }
            } message: {
                Text("Enter your display name")
            }
            // Error alert
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            // Subscription error alert
            .alert("Subscription Error", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
                Button("OK") {
                    subscriptionManager.errorMessage = nil
                }
            } message: {
                Text(subscriptionManager.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Load Settings
    
    private func loadSettingsFromSession() {
        if let settings = session.userSettings {
            notificationsEnabled = settings.notificationsEnabled
            preferredStudyMode = settings.preferredStudyMode
            
            if let time = settings.reminderTimeComponents {
                var components = DateComponents()
                components.hour = time.hour
                components.minute = time.minute
                if let date = Calendar.current.date(from: components) {
                    dailyReminderTime = date
                }
            }
        }
        
        editingDisplayName = session.userProfile?.displayName ?? ""
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Avatar with edit button
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(AppColors.tanDark)
                        .frame(width: 80, height: 80)
                    
                    Text(userInitial)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppColors.primary)
                }
            }
            
            // Display name (editable)
            Button {
                editingDisplayName = session.userProfile?.displayName ?? ""
                showEditDisplayName = true
            } label: {
                HStack(spacing: AppSpacing.xxs) {
                    Text(session.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppColors.primary)
                    
                    Image(systemName: "pencil.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // User email
            if let email = session.currentUser?.email {
                Text(email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Account status with premium badge
            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(AppColors.success)
                    .frame(width: 8, height: 8)
                Text("Signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if subscriptionManager.isPremium {
                    PremiumBadge(small: true)
                }
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
        // First try display name, then email
        if let displayName = session.userProfile?.displayName,
           !displayName.isEmpty,
           let first = displayName.first {
            return String(first).uppercased()
        }
        
        guard let email = session.currentUser?.email,
              let first = email.first else {
            return "?"
        }
        return String(first).uppercased()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Your Progress")
            
            HStack(spacing: 0) {
                statItem(
                    value: "\(session.userProfile?.totalBooks ?? 0)",
                    label: "Books",
                    icon: "books.vertical.fill",
                    color: .blue
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                
                statItem(
                    value: "\(session.userProfile?.totalWords ?? 0)",
                    label: "Words",
                    icon: "textformat.abc",
                    color: .purple
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                
                statItem(
                    value: "\(session.userProfile?.masteredWords ?? 0)",
                    label: "Mastered",
                    icon: "checkmark.circle.fill",
                    color: AppColors.success
                )
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                
                statItem(
                    value: "\(session.userProfile?.totalStudySessions ?? 0)",
                    label: "Sessions",
                    icon: "brain.head.profile",
                    color: .orange
                )
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
        }
    }
    
    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: AppSpacing.xxs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Save Display Name
    
    private func saveDisplayName() {
        guard !editingDisplayName.isEmpty else { return }
        
        isSavingDisplayName = true
        
        Task {
            do {
                try await session.updateDisplayName(editingDisplayName)
                logger.info("👤 Display name updated to: \(editingDisplayName)")
            } catch {
                logger.error("👤 Failed to update display name: \(error.localizedDescription)")
                errorMessage = "Failed to update display name: \(error.localizedDescription)"
                showError = true
            }
            
            isSavingDisplayName = false
        }
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
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Preferences")
            
            VStack(spacing: 0) {
                // Notifications toggle
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "bell.fill")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Daily Reminders")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Get reminded to study daily")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                        .tint(AppColors.primary)
                        .onChange(of: notificationsEnabled) { _, newValue in
                            saveNotificationSettings()
                        }
                }
                .padding(AppSpacing.md)
                
                // Reminder time (only show if notifications enabled)
                if notificationsEnabled {
                    Divider()
                        .padding(.leading, 52)
                    
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "clock.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder Time")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primary)
                            
                            Text("When to send daily reminder")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: dailyReminderTime) { _, _ in
                                saveNotificationSettings()
                            }
                    }
                    .padding(AppSpacing.md)
                }
                
                Divider()
                    .padding(.leading, 52)
                
                // Preferred study mode
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(Color.purple.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.subheadline)
                            .foregroundStyle(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Preferred Study Mode")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Your default study experience")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            preferredStudyMode = "flashcards"
                            savePreferredStudyMode()
                        } label: {
                            Label("Flashcards", systemImage: preferredStudyMode == "flashcards" ? "checkmark" : "")
                        }
                        
                        if subscriptionManager.isPremium {
                            Button {
                                preferredStudyMode = "multiple_choice"
                                savePreferredStudyMode()
                            } label: {
                                Label("Multiple Choice", systemImage: preferredStudyMode == "multiple_choice" ? "checkmark" : "")
                            }
                            
                            Button {
                                preferredStudyMode = "fill_in_blank"
                                savePreferredStudyMode()
                            } label: {
                                Label("Fill in Blank", systemImage: preferredStudyMode == "fill_in_blank" ? "checkmark" : "")
                            }
                        } else {
                            Button {
                                showUpgradeModal = true
                            } label: {
                                Label("Multiple Choice 🔒", systemImage: "")
                            }
                            
                            Button {
                                showUpgradeModal = true
                            } label: {
                                Label("Fill in Blank 🔒", systemImage: "")
                            }
                        }
                    } label: {
                        HStack(spacing: AppSpacing.xxs) {
                            Text(studyModeDisplayName)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(AppSpacing.md)
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
        }
    }
    
    /// Display name for the selected study mode
    private var studyModeDisplayName: String {
        switch preferredStudyMode {
        case "flashcards": return "Flashcards"
        case "multiple_choice": return "Multiple Choice"
        case "fill_in_blank": return "Fill in Blank"
        default: return "Flashcards"
        }
    }
    
    /// Saves notification settings to backend
    private func saveNotificationSettings() {
        guard networkMonitor.isConnected else {
            logger.warning("⚙️ Offline - notification settings will sync when online")
            return
        }
        
        let timeString = formatTimeForStorage(dailyReminderTime)
        
        Task {
            do {
                try await session.updateNotificationSettings(enabled: notificationsEnabled, reminderTime: timeString)
                logger.info("⚙️ Notification settings saved: enabled=\(notificationsEnabled), time=\(timeString)")
            } catch {
                logger.error("⚙️ Failed to save notification settings: \(error.localizedDescription)")
                errorMessage = "Failed to save notification settings"
                showError = true
            }
        }
    }
    
    /// Saves preferred study mode to backend
    private func savePreferredStudyMode() {
        guard networkMonitor.isConnected else {
            logger.warning("⚙️ Offline - study mode preference will sync when online")
            return
        }
        
        Task {
            do {
                try await session.updatePreferredStudyMode(preferredStudyMode)
                logger.info("⚙️ Preferred study mode saved: \(preferredStudyMode)")
            } catch {
                logger.error("⚙️ Failed to save study mode preference: \(error.localizedDescription)")
                errorMessage = "Failed to save study mode preference"
                showError = true
            }
        }
    }
    
    /// Formats a Date to HH:mm string for storage
    private func formatTimeForStorage(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - App Section
    
    private var appSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader("Subscription")
            
            VStack(spacing: 0) {
                // Premium status
                if subscriptionManager.isPremium {
                    // Premium user
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "crown.fill")
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("Premium")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primary)
                                
                                PremiumBadge(small: true)
                            }
                            
                            Text("All features unlocked • No ads")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .padding(AppSpacing.md)
                } else {
                    // Free user - show upgrade option
                    Button {
                        showUpgradeModal = true
                    } label: {
                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [.yellow.opacity(0.2), .orange.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "star.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.orange)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.primary)
                                
                                Text("$2.99/month • Unlock all features")
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
                
                Divider()
                    .padding(.leading, 52)
                
                // Restore purchases
                Button {
                    Task {
                        await subscriptionManager.restorePurchases()
                    }
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(Color.blue.opacity(0.15))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(.blue)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Restore Purchases")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.primary)
                            
                            Text("Restore your Premium subscription")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if subscriptionManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(AppSpacing.md)
                }
                .disabled(subscriptionManager.isProcessing)
                
                Divider()
                    .padding(.leading, 52)
                
                // Free tier limits (only show for free users)
                if !subscriptionManager.isPremium {
                    VStack(spacing: AppSpacing.sm) {
                        HStack(spacing: AppSpacing.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                    .fill(Color.purple.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "chart.bar.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Tier Limits")
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.primary)
                                
                                Text("Upgrade for unlimited access")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        VStack(spacing: AppSpacing.xs) {
                            freeTierLimitRow(icon: "books.vertical", label: "Books", limit: "\(FreemiumLimits.maxBooks) max")
                            freeTierLimitRow(icon: "textformat.abc", label: "Words per book", limit: "\(FreemiumLimits.maxWordsPerBook) max")
                            freeTierLimitRow(icon: "brain.head.profile", label: "Study modes", limit: "Flashcards only")
                        }
                        .padding(.leading, 44)
                    }
                    .padding(AppSpacing.md)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
            
            // Network section
            sectionHeader("Network")
                .padding(.top, AppSpacing.md)
            
            VStack(spacing: 0) {
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
    
    /// Helper view for free tier limit row
    private func freeTierLimitRow(icon: String, label: String, limit: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(limit)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
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
            Text("Read & Recall")
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


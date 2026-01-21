//
//  PreferencesView.swift
//  BookVocab
//
//  Third screen of onboarding - study preferences.
//  Collects preferred study mode and notification settings.
//

import SwiftUI
import UserNotifications

/// Preferences screen - collects study preferences
struct PreferencesView: View {
    
    // MARK: - Bindings
    
    @Binding var preferredStudyMode: String
    @Binding var notificationsEnabled: Bool
    @Binding var dailyReminderTime: Date
    
    // MARK: - Properties
    
    var onContinue: () -> Void
    
    // MARK: - State
    
    @State private var hasAppeared: Bool = false
    @State private var permissionDenied: Bool = false
    @State private var showPermissionAlert: Bool = false
    
    // MARK: - Study Modes
    
    private let studyModes: [(id: String, name: String, icon: String, description: String)] = [
        ("flashcards", "Flashcards", "rectangle.on.rectangle.angled", "Flip cards to reveal definitions"),
        ("multiple_choice", "Multiple Choice", "list.bullet.circle", "Pick the correct answer"),
        ("fill_in_blank", "Fill in the Blank", "text.cursor", "Type the word from its definition")
    ]
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.xl) {
                // Header
                headerSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Study mode selection
                studyModeSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Notification settings
                notificationSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Continue button
                continueSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.vertical, AppSpacing.xl)
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.tanDark)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            Text("Study Preferences")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)
            
            Text("Customize your learning experience")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Study Mode Section
    
    private var studyModeSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("PREFERRED STUDY MODE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(spacing: AppSpacing.sm) {
                ForEach(studyModes, id: \.id) { mode in
                    studyModeCard(mode: mode)
                }
            }
        }
    }
    
    private func studyModeCard(mode: (id: String, name: String, icon: String, description: String)) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                preferredStudyMode = mode.id
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .fill(preferredStudyMode == mode.id ? AppColors.primary : AppColors.tanDark)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: mode.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(preferredStudyMode == mode.id ? .white : AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.primary)
                    
                    Text(mode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if preferredStudyMode == mode.id {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
            }
            .padding(AppSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .stroke(preferredStudyMode == mode.id ? AppColors.primary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Notification Section
    
    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("DAILY REMINDERS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                // Enable toggle
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "bell.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Study Reminders")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.primary)
                        
                        Text("Get reminded to practice daily")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { notificationsEnabled },
                        set: { newValue in
                            if newValue {
                                requestNotificationPermission()
                            } else {
                                notificationsEnabled = false
                            }
                        }
                    ))
                        .labelsHidden()
                        .tint(AppColors.primary)
                }
                .padding(AppSpacing.md)
                
                // Reminder time (if enabled)
                if notificationsEnabled {
                    Divider()
                        .padding(.leading, 60)
                    
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "clock.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(.orange)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder Time")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.primary)
                            
                            Text("When to send daily notification")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        DatePicker("", selection: $dailyReminderTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .onChange(of: dailyReminderTime) { _, _ in
                                // Reschedule notification when time changes
                                if notificationsEnabled {
                                    scheduleReminderNotification()
                                }
                            }
                    }
                    .padding(AppSpacing.md)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(AppColors.cardBackground)
            )
        }
    }
    
    // MARK: - Continue Section
    
    private var continueSection: some View {
        Button(action: onContinue) {
            HStack {
                Text("Continue")
                    .fontWeight(.semibold)
                
                Image(systemName: "arrow.right")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.primary)
        .padding(.top, AppSpacing.md)
        .alert("Notifications Disabled", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To receive study reminders, please enable notifications in Settings.")
        }
    }
    
    // MARK: - Notification Permission
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    notificationsEnabled = true
                    scheduleReminderNotification()
                } else {
                    notificationsEnabled = false
                    permissionDenied = true
                    showPermissionAlert = true
                }
            }
        }
    }
    
    private func scheduleReminderNotification() {
        // Remove any existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Study! 📚"
        content.body = "Your vocabulary words are waiting. Let's learn something new!"
        content.sound = .default
        
        // Get hour and minute from selected time
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: dailyReminderTime)
        let minute = calendar.component(.minute, from: dailyReminderTime)
        
        // Create daily trigger at selected time
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "daily_study_reminder",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                print("✅ Daily reminder scheduled for \(hour):\(String(format: "%02d", minute))")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PreferencesView(
        preferredStudyMode: .constant("flashcards"),
        notificationsEnabled: .constant(true),
        dailyReminderTime: .constant(Date()),
        onContinue: {}
    )
}

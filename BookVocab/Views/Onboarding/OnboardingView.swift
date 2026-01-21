//
//  OnboardingView.swift
//  BookVocab
//
//  Main onboarding flow coordinator.
//  Manages navigation between onboarding steps for new users.
//

import SwiftUI
import os.log

/// Logger for onboarding
private let logger = Logger(subsystem: "com.bookvocab.app", category: "Onboarding")

/// Onboarding steps enum
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case profileSetup = 1
    case preferences = 2
    case paywall = 3
    case completion = 4
    
    var title: String {
        switch self {
        case .welcome: return "Welcome"
        case .profileSetup: return "Profile"
        case .preferences: return "Preferences"
        case .paywall: return "Premium"
        case .completion: return "Complete"
        }
    }
}

/// Main onboarding view that coordinates the multi-step flow.
struct OnboardingView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - State
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var displayName: String = ""
    @State private var preferredStudyMode: String = "flashcards"
    @State private var notificationsEnabled: Bool = false
    @State private var dailyReminderTime: Date = {
        var components = DateComponents()
        components.hour = 8
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    /// Callback when onboarding completes
    var onComplete: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppColors.tan, AppColors.tanDark.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress indicator (except for welcome and completion)
                if currentStep != .welcome && currentStep != .completion {
                    progressIndicator
                        .padding(.top, AppSpacing.lg)
                }
                
                // Content
                TabView(selection: $currentStep) {
                    WelcomeView(onContinue: { nextStep() })
                        .tag(OnboardingStep.welcome)
                    
                    ProfileSetupView(
                        displayName: $displayName,
                        onContinue: { saveProfileAndContinue() }
                    )
                    .tag(OnboardingStep.profileSetup)
                    
                    PreferencesView(
                        preferredStudyMode: $preferredStudyMode,
                        notificationsEnabled: $notificationsEnabled,
                        dailyReminderTime: $dailyReminderTime,
                        onContinue: { savePreferencesAndContinue() }
                    )
                    .tag(OnboardingStep.preferences)
                    
                    PaywallView(
                        onStartTrial: { startTrialAndContinue() },
                        onContinueFree: { nextStep() },
                        onRestorePurchases: { restorePurchases() }
                    )
                    .tag(OnboardingStep.paywall)
                    
                    OnboardingCompletionView(
                        displayName: displayName,
                        isPremium: subscriptionManager.isPremium,
                        onFinish: { completeOnboarding() }
                    )
                    .tag(OnboardingStep.completion)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
        .onAppear {
            // Pre-fill display name from email if available
            if let email = session.currentUser?.email {
                displayName = email.components(separatedBy: "@").first ?? ""
            }
            
            logger.info("🎓 Onboarding started")
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(1...3, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep.rawValue ? AppColors.primary : Color.gray.opacity(0.3))
                    .frame(width: step <= currentStep.rawValue ? 24 : 8, height: 8)
                    .animation(.spring(), value: currentStep)
            }
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
    }
    
    // MARK: - Navigation
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let next = OnboardingStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
                logger.debug("🎓 Moving to step: \(next.title)")
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prev
            }
        }
    }
    
    // MARK: - Save Actions
    
    private func saveProfileAndContinue() {
        logger.info("🎓 Saving profile: displayName=\(displayName)")
        
        Task {
            do {
                // Update display name
                try await session.updateDisplayName(displayName.isEmpty ? "Reader" : displayName)
                
                // Move to next step
                await MainActor.run {
                    nextStep()
                }
            } catch {
                logger.error("🎓 Failed to save profile: \(error.localizedDescription)")
                // Continue anyway - can be updated later
                nextStep()
            }
        }
    }
    
    private func savePreferencesAndContinue() {
        logger.info("🎓 Saving preferences: mode=\(preferredStudyMode), notifications=\(notificationsEnabled)")
        
        Task {
            do {
                // Update study mode
                try await session.updatePreferredStudyMode(preferredStudyMode)
                
                // Update notification settings
                let timeString = formatTimeForStorage(dailyReminderTime)
                try await session.updateNotificationSettings(enabled: notificationsEnabled, reminderTime: timeString)
                
                // Move to next step
                await MainActor.run {
                    nextStep()
                }
            } catch {
                logger.error("🎓 Failed to save preferences: \(error.localizedDescription)")
                // Continue anyway
                nextStep()
            }
        }
    }
    
    private func startTrialAndContinue() {
        logger.info("🎓 Starting free trial")
        
        Task {
            await subscriptionManager.purchaseMonthlyPremium()
            
            // Move to completion regardless (user can dismiss if cancelled)
            await MainActor.run {
                nextStep()
            }
        }
    }
    
    private func restorePurchases() {
        logger.info("🎓 Restoring purchases from onboarding")
        
        Task {
            await subscriptionManager.restorePurchases()
            
            // If restored successfully and premium, move to completion
            if subscriptionManager.isPremium {
                await MainActor.run {
                    nextStep()
                }
            }
        }
    }
    
    private func completeOnboarding() {
        logger.info("🎓 Onboarding complete!")
        
        Task {
            // Mark onboarding as complete
            do {
                try await session.completeOnboarding()
            } catch {
                logger.error("🎓 Failed to mark onboarding complete: \(error.localizedDescription)")
            }
            
            // Track analytics
            AnalyticsService.shared.track(.signUp, properties: [
                "onboarding_completed": true,
                "is_premium": subscriptionManager.isPremium,
                "study_mode": preferredStudyMode
            ])
            
            // Call completion handler
            await MainActor.run {
                onComplete()
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatTimeForStorage(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(UserSessionViewModel())
}

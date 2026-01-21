//
//  PaywallView.swift
//  BookVocab
//
//  Fourth screen of onboarding - subscription paywall.
//  Explains premium benefits and offers free trial.
//  App Store compliant with clear trial terms.
//

import SwiftUI

/// Paywall screen - subscription offer with free trial
struct PaywallView: View {
    
    // MARK: - Environment
    
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - Properties
    
    var onStartTrial: () -> Void
    var onContinueFree: () -> Void
    var onRestorePurchases: () -> Void
    
    // MARK: - State
    
    @State private var hasAppeared: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPrivacy: Bool = false
    
    // MARK: - Premium Features
    
    private let premiumFeatures: [(icon: String, title: String, description: String, color: Color)] = [
        ("infinity", "Unlimited Books", "Add as many books as you want", .blue),
        ("textformat.abc", "Unlimited Words", "No limits per book", .purple),
        ("brain.head.profile", "All Study Modes", "Flashcards, Multiple Choice & Fill-in-the-Blank", .orange),
        ("xmark.rectangle", "No Ads", "Completely ad-free experience", .green)
    ]
    
    // MARK: - Free Limitations
    
    private let freeLimitations: [(icon: String, text: String)] = [
        ("6.circle", "Up to 6 books"),
        ("16.circle", "16 words per book"),
        ("rectangle.on.rectangle.angled", "Flashcards only"),
        ("rectangle.badge.checkmark", "Ads enabled")
    ]
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header
                headerSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Premium benefits
                premiumBenefitsSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Trial offer
                trialOfferSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Free option
                freeOptionSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                
                // Legal links
                legalSection
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.vertical, AppSpacing.lg)
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.2)) {
                hasAppeared = true
            }
        }
        .sheet(isPresented: $showTerms) {
            LegalDocumentView(title: "Terms of Service", type: .terms)
        }
        .sheet(isPresented: $showPrivacy) {
            LegalDocumentView(title: "Privacy Policy", type: .privacy)
        }
        // Error alert
        .alert("Error", isPresented: .constant(subscriptionManager.errorMessage != nil)) {
            Button("OK") {
                subscriptionManager.errorMessage = nil
            }
        } message: {
            Text(subscriptionManager.errorMessage ?? "An error occurred")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow.opacity(0.3), .orange.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("Unlock Premium")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                
                Text("Start your free trial today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Premium Benefits Section
    
    private var premiumBenefitsSection: some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(premiumFeatures, id: \.title) { feature in
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                            .fill(feature.color.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: feature.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(feature.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppColors.primary)
                        
                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                .padding(AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(AppColors.cardBackground)
                )
            }
        }
    }
    
    // MARK: - Trial Offer Section
    
    private var trialOfferSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Trial badge
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundStyle(.green)
                Text("1 MONTH FREE TRIAL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule()
                    .fill(Color.green.opacity(0.15))
            )
            
            // Price info
            VStack(spacing: AppSpacing.xxs) {
                if let product = subscriptionManager.products.first {
                    Text("Then \(product.displayPrice)/month")
                        .font(.headline)
                        .foregroundStyle(AppColors.primary)
                } else {
                    Text("Then $1.99/month")
                        .font(.headline)
                        .foregroundStyle(AppColors.primary)
                }
                
                Text("Cancel anytime during trial • No charge until trial ends")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Start trial button
            Button {
                onStartTrial()
            } label: {
                HStack {
                    if subscriptionManager.isProcessing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                        Text("Start Free Trial")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.primary)
            .disabled(subscriptionManager.isProcessing)
            
            // Trial terms
            Text("Payment will be charged to your Apple ID account at the confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. Your account will be charged for renewal within 24 hours prior to the end of the current period. You can manage and cancel your subscriptions by going to your account settings on the App Store after purchase.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(AppColors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.yellow.opacity(0.5), .orange.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                )
        )
    }
    
    // MARK: - Free Option Section
    
    private var freeOptionSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Divider with "OR"
            HStack {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                
                Text("OR")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.sm)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
            }
            
            // Free tier info
            VStack(spacing: AppSpacing.sm) {
                Text("Continue with Free")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
                
                HStack(spacing: AppSpacing.lg) {
                    ForEach(freeLimitations, id: \.text) { limit in
                        VStack(spacing: 4) {
                            Image(systemName: limit.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(limit.text)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Continue free button
            Button(action: onContinueFree) {
                Text("Maybe Later")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Restore purchases
            Button(action: onRestorePurchases) {
                HStack {
                    if subscriptionManager.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Restore Purchases")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .disabled(subscriptionManager.isProcessing)
            
            // Legal links
            HStack(spacing: AppSpacing.lg) {
                Button {
                    showTerms = true
                } label: {
                    Text("Terms of Service")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("•")
                    .foregroundStyle(.secondary)
                
                Button {
                    showPrivacy = true
                } label: {
                    Text("Privacy Policy")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.top, AppSpacing.md)
    }
}

// MARK: - Legal Document View

struct LegalDocumentView: View {
    let title: String
    let type: LegalDocumentType
    
    @Environment(\.dismiss) private var dismiss
    
    enum LegalDocumentType {
        case terms
        case privacy
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text(documentContent)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .padding(AppSpacing.horizontalPadding)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var documentContent: String {
        switch type {
        case .terms:
            return """
            Terms of Service
            
            Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))
            
            1. ACCEPTANCE OF TERMS
            
            By using Read & Recall, you agree to these Terms of Service. If you do not agree, please do not use the app.
            
            2. SUBSCRIPTION TERMS
            
            Read & Recall offers a premium subscription with a 1-month free trial:
            - Trial Period: 1 month from the date of subscription
            - After Trial: Automatically converts to paid subscription
            - Billing: Monthly subscription at $1.99/month
            - Cancellation: Cancel anytime through App Store settings
            - Refunds: Subject to Apple's refund policy
            
            3. AUTO-RENEWAL
            
            Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period.
            
            4. MANAGING SUBSCRIPTIONS
            
            You can manage or cancel your subscription in your App Store account settings.
            
            5. USER CONTENT
            
            You retain ownership of any vocabulary words and notes you add to the app. We may use anonymized, aggregated data to improve our service.
            
            6. DISCLAIMER
            
            The app is provided "as is" without warranties of any kind. We are not responsible for any errors in dictionary definitions or data loss.
            
            7. CONTACT
            
            For questions about these terms, contact us at support@readandrecall.app
            """
            
        case .privacy:
            return """
            Privacy Policy
            
            Last updated: \(Date().formatted(date: .abbreviated, time: .omitted))
            
            1. INFORMATION WE COLLECT
            
            - Account Information: Email address for authentication
            - User Content: Books, vocabulary words, and study progress
            - Usage Data: App usage patterns, study session statistics
            - Device Information: Device type, OS version (for debugging)
            
            2. HOW WE USE INFORMATION
            
            - To provide and improve our service
            - To sync your data across devices
            - To send study reminders (if enabled)
            - To analyze usage and improve features
            
            3. DATA STORAGE
            
            Your data is stored securely using:
            - Supabase (cloud database with encryption)
            - Local device storage (for offline access)
            
            4. DATA SHARING
            
            We do not sell your personal data. We may share anonymized, aggregated data for analytics.
            
            5. THIRD-PARTY SERVICES
            
            We use:
            - Supabase (authentication and database)
            - Mixpanel (analytics)
            - Google AdMob (advertising for free users)
            - Apple StoreKit (subscriptions)
            
            6. YOUR RIGHTS
            
            You can:
            - Access your data through the app
            - Delete your account and data
            - Opt out of analytics
            - Disable notifications
            
            7. DATA RETENTION
            
            We retain your data while your account is active. Upon deletion, data is permanently removed within 30 days.
            
            8. CHILDREN'S PRIVACY
            
            Read & Recall is not intended for children under 13. We do not knowingly collect data from children.
            
            9. CONTACT
            
            For privacy concerns, contact us at privacy@readandrecall.app
            """
        }
    }
}

// MARK: - Preview

#Preview {
    PaywallView(
        onStartTrial: {},
        onContinueFree: {},
        onRestorePurchases: {}
    )
}

//
//  UpgradeView.swift
//  BookVocab
//
//  Modal view encouraging users to upgrade to Premium.
//  Shows current limit exceeded and premium benefits.
//
//  Features:
//  - Context-aware messaging based on upgrade reason
//  - Premium benefits list
//  - Purchase button with pricing
//  - Restore purchases link
//  - Loading and error states
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "UpgradeView")

struct UpgradeView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - Properties
    
    /// The reason for showing the upgrade view
    var reason: UpgradeReason = .generic
    
    // MARK: - State
    
    @State private var showError: Bool = false
    @State private var localErrorMessage: String = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // Header
                    headerSection
                    
                    // Limit message (if applicable)
                    if reason != .generic {
                        limitMessageCard(for: reason)
                    }
                    
                    // Benefits
                    benefitsSection
                    
                    // Pricing
                    pricingSection
                    
                    // Restore purchases
                    restoreSection
                }
                .padding(AppSpacing.horizontalPadding)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Go Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        subscriptionManager.showUpgradeModal = false
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(localErrorMessage)
            }
            .onChange(of: subscriptionManager.isPremium) { _, isPremium in
                if isPremium {
                    // Successfully upgraded - dismiss
                    subscriptionManager.showUpgradeModal = false
                    dismiss()
                }
            }
            .onChange(of: subscriptionManager.errorMessage) { _, error in
                if let error = error {
                    localErrorMessage = error
                    showError = true
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Crown icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }
            .shadow(color: .orange.opacity(0.3), radius: 20, x: 0, y: 10)
            
            Text("Unlock Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Get unlimited access to all features")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppSpacing.lg)
    }
    
    // MARK: - Limit Message
    
    private func limitMessageCard(for reason: UpgradeReason) -> some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: reason.icon)
                    .foregroundStyle(.orange)
                
                Text(reason.title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(reason.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
    
    // MARK: - Benefits
    
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Premium Benefits")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: AppSpacing.sm) {
                BenefitRow(
                    icon: "books.vertical.fill",
                    title: "Unlimited Books",
                    description: "Add as many books as you want"
                )
                
                BenefitRow(
                    icon: "textformat.abc",
                    title: "Unlimited Words",
                    description: "No limit on vocabulary per book"
                )
                
                BenefitRow(
                    icon: "brain.head.profile",
                    title: "All Study Modes",
                    description: "Flashcards, Multiple Choice & Fill-in-the-Blank"
                )
                
                BenefitRow(
                    icon: "xmark.rectangle.fill",
                    title: "No Ads",
                    description: "Enjoy an ad-free experience"
                )
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
    }
    
    // MARK: - Pricing
    
    private var pricingSection: some View {
        VStack(spacing: AppSpacing.md) {
            if let product = subscriptionManager.products.first {
                // Price display
                VStack(spacing: AppSpacing.xs) {
                    Text(product.displayPrice)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("per month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                // Purchase button
                Button {
                    Task {
                        await subscriptionManager.purchaseMonthlyPremium()
                    }
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if subscriptionManager.isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "crown.fill")
                            Text("Subscribe Now")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .disabled(subscriptionManager.isProcessing)
                
            } else {
                // Fallback if products not loaded
                VStack(spacing: AppSpacing.xs) {
                    Text("$1.99")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                    
                    Text("per month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    Task {
                        await subscriptionManager.loadProducts()
                    }
                } label: {
                    Text("Load Pricing")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppColors.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
            }
            
            // Terms
            Text("Cancel anytime. Subscription auto-renews monthly.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Restore
    
    private var restoreSection: some View {
        Button {
            Task {
                await subscriptionManager.restorePurchases()
            }
        } label: {
            HStack(spacing: AppSpacing.xs) {
                if subscriptionManager.isProcessing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Image(systemName: "arrow.clockwise")
                }
                Text("Restore Purchases")
            }
            .font(.subheadline)
            .foregroundStyle(.blue)
        }
        .disabled(subscriptionManager.isProcessing)
    }
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .padding(.vertical, AppSpacing.xs)
    }
}

// MARK: - Preview

#Preview {
    UpgradeView(reason: .bookLimit)
}


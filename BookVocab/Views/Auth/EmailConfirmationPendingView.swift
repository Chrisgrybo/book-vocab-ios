//
//  EmailConfirmationPendingView.swift
//  BookVocab
//
//  View displayed after signup when email confirmation is required.
//  Shows instructions and allows resending the confirmation email.
//
//  Features:
//  - Clear instructions for email confirmation
//  - Resend confirmation email button
//  - Return to login option
//  - Timer cooldown for resend button
//

import SwiftUI

/// View displayed when a user needs to confirm their email after signing up.
struct EmailConfirmationPendingView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    
    // MARK: - State
    
    /// Loading state during resend
    @State private var isResending: Bool = false
    
    /// Success message after resend
    @State private var showResendSuccess: Bool = false
    
    /// Error message
    @State private var errorMessage: String?
    
    /// Cooldown timer for resend button
    @State private var resendCooldown: Int = 0
    
    /// Timer for cooldown
    @State private var cooldownTimer: Timer?
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    // MARK: - Computed Properties
    
    /// Whether the resend button should be disabled
    private var isResendDisabled: Bool {
        isResending || resendCooldown > 0
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            AppColors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    Spacer(minLength: AppSpacing.xxxl)
                    
                    // Email icon
                    emailIllustration
                    
                    // Header text
                    headerSection
                    
                    // Email display
                    emailCard
                    
                    // Instructions
                    instructionsSection
                    
                    // Action buttons
                    actionButtons
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.horizontalPadding)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
        .onDisappear {
            cooldownTimer?.invalidate()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - View Components
    
    /// Animated email illustration
    private var emailIllustration: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(AppColors.primary.opacity(0.15))
                .frame(width: 140, height: 140)
            
            // Envelope with badge
            ZStack {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.primary)
                
                // Notification badge
                Circle()
                    .fill(AppColors.warning)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "exclamationmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: 28, y: -24)
            }
        }
        .scaleEffect(hasAppeared ? 1 : 0.7)
        .opacity(hasAppeared ? 1 : 0)
    }
    
    /// Header text
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Verify Your Email")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)
            
            Text("We've sent a confirmation link to your email address")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    /// Card showing the email address
    private var emailCard: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "at")
                .font(.title2)
                .foregroundStyle(AppColors.primary)
                .frame(width: 32)
            
            Text(session.pendingConfirmationEmail ?? "your email")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(AppSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: 0, y: AppShadow.card.y)
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    /// Step-by-step instructions
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("What's Next?")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            instructionRow(number: 1, text: "Check your email inbox")
            instructionRow(number: 2, text: "Click the confirmation link")
            instructionRow(number: 3, text: "Return here to sign in")
            
            // Tips
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
                Text("Don't forget to check your spam folder!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(AppColors.tanDark.opacity(0.3))
        )
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    /// Single instruction row
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            // Number circle
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(AppColors.primary))
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
        }
    }
    
    /// Action buttons
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.md) {
            // Resend button
            Button {
                Task { await resendEmail() }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.clockwise")
                        if resendCooldown > 0 {
                            Text("Resend in \(resendCooldown)s")
                        } else if showResendSuccess {
                            Text("Email Sent!")
                        } else {
                            Text("Resend Confirmation Email")
                        }
                    }
                }
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .fill(isResendDisabled ? Color.gray.opacity(0.3) : AppColors.primary)
                )
                .foregroundStyle(.white)
            }
            .disabled(isResendDisabled)
            
            // Back to login button
            Button {
                session.clearPendingConfirmation()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "arrow.left")
                    Text("Back to Login")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.primary)
            }
        }
        .opacity(hasAppeared ? 1 : 0)
    }
    
    // MARK: - Actions
    
    /// Resends the confirmation email
    private func resendEmail() async {
        guard let email = session.pendingConfirmationEmail else { return }
        
        isResending = true
        errorMessage = nil
        showResendSuccess = false
        
        do {
            try await session.resendConfirmationEmail(to: email)
            
            // Show success and start cooldown
            showResendSuccess = true
            startCooldown()
            
        } catch {
            errorMessage = "Failed to resend email. Please try again."
        }
        
        isResending = false
    }
    
    /// Starts the cooldown timer (60 seconds)
    private func startCooldown() {
        resendCooldown = 60
        
        cooldownTimer?.invalidate()
        cooldownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if resendCooldown > 0 {
                resendCooldown -= 1
            } else {
                cooldownTimer?.invalidate()
                showResendSuccess = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let session = UserSessionViewModel()
    session.pendingEmailConfirmation = true
    session.pendingConfirmationEmail = "test@example.com"
    
    return EmailConfirmationPendingView()
        .environmentObject(session)
}

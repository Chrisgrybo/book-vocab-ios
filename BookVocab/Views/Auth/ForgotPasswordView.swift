//
//  ForgotPasswordView.swift
//  BookVocab
//
//  View for requesting a password reset email.
//  Accessed from the login screen via "Forgot Password?" link.
//
//  Features:
//  - Email input with validation
//  - Sends password reset email via Supabase
//  - Success confirmation with instructions
//  - Network awareness
//

import SwiftUI

/// View for requesting a password reset email.
/// Presents as a sheet from the login screen.
struct ForgotPasswordView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSessionViewModel
    
    // MARK: - State
    
    /// Email address for password reset
    @State private var email: String = ""
    
    /// Loading state during request
    @State private var isLoading: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String?
    
    /// Whether the email was sent successfully
    @State private var emailSent: Bool = false
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates email format
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.contains("@") && trimmed.contains(".")
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                if emailSent {
                    // Success state
                    successView
                } else {
                    // Email entry form
                    formView
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(emailSent ? "Done" : "Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(emailSent ? AppColors.primary : .secondary)
                }
            }
            .onAppear {
                withAnimation(AppAnimation.spring.delay(0.1)) {
                    hasAppeared = true
                }
            }
            // Error alert
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Form View
    
    private var formView: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Header illustration
                headerSection
                    .padding(.top, AppSpacing.xl)
                
                // Form card
                VStack(spacing: AppSpacing.lg) {
                    // Email field
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Email Address")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "envelope.fill")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                            
                            TextField("your@email.com", text: $email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .padding(AppSpacing.md)
                        .background(AppColors.groupedBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                    }
                    
                    // Send button
                    sendButton
                        .padding(.top, AppSpacing.sm)
                }
                .padding(AppSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                        .fill(AppColors.cardBackground)
                        .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: 0, y: AppShadow.card.y)
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                
                Spacer(minLength: AppSpacing.xl)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
        }
    }
    
    // MARK: - Success View
    
    private var successView: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()
            
            // Success illustration
            ZStack {
                Circle()
                    .fill(AppColors.success.opacity(0.2))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(AppColors.success)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            
            VStack(spacing: AppSpacing.md) {
                Text("Check Your Email")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                
                Text("We've sent a password reset link to:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(email)
                    .font(.headline)
                    .foregroundStyle(AppColors.primary)
                
                Text("Click the link in the email to reset your password. The link will expire in 24 hours.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, AppSpacing.sm)
            }
            .padding(.horizontal, AppSpacing.xl)
            
            // Tips section
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Didn't receive the email?")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "folder.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Check your spam folder")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Text("Wait a few minutes and try again")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.tanDark.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            .padding(.horizontal, AppSpacing.horizontalPadding)
            
            Spacer()
            
            // Done button
            Button {
                dismiss()
            } label: {
                Text("Return to Login")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .fill(AppColors.primary)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.bottom, AppSpacing.xl)
        }
    }
    
    // MARK: - View Components
    
    /// Header with icon and description
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "key.horizontal.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            Text("Forgot Password?")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)
            
            Text("Enter your email address and we'll send you a link to reset your password")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
        }
    }
    
    /// Send reset email button
    private var sendButton: some View {
        Button {
            Task {
                await sendResetEmail()
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                    Text("Send Reset Link")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(isEmailValid && !isLoading ? AppColors.primary : Color.gray.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .disabled(!isEmailValid || isLoading)
        .animation(AppAnimation.smooth, value: isEmailValid)
    }
    
    // MARK: - Actions
    
    /// Sends the password reset email
    private func sendResetEmail() async {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await session.sendPasswordResetEmail(to: email.trimmingCharacters(in: .whitespaces))
            
            // Success - show confirmation
            withAnimation(AppAnimation.spring) {
                emailSent = true
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    ForgotPasswordView()
        .environmentObject(UserSessionViewModel())
}


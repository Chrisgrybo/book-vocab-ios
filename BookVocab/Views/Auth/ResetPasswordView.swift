//
//  ResetPasswordView.swift
//  BookVocab
//
//  View for setting a new password after clicking email reset link.
//  Displayed when the app is opened via the password reset deep link.
//
//  Features:
//  - New password with confirmation
//  - Validation feedback
//  - Success/error handling
//  - Navigation back to login on success
//

import SwiftUI

/// View for setting a new password after clicking a reset link in email.
/// Displayed when the app handles a password reset deep link.
struct ResetPasswordView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSessionViewModel
    
    // MARK: - State
    
    /// New password to set
    @State private var newPassword: String = ""
    
    /// Confirmation of new password
    @State private var confirmPassword: String = ""
    
    /// Loading state during password update
    @State private var isLoading: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String?
    
    /// Success state
    @State private var showSuccess: Bool = false
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    // MARK: - Properties
    
    /// Callback when password is successfully reset
    var onSuccess: (() -> Void)?
    
    // MARK: - Computed Properties
    
    /// Validates the form inputs
    private var isFormValid: Bool {
        let hasNewPassword = !newPassword.isEmpty
        let hasConfirmPassword = !confirmPassword.isEmpty
        let newPasswordValid = newPassword.count >= 6
        let passwordsMatch = newPassword == confirmPassword
        
        return hasNewPassword && hasConfirmPassword && newPasswordValid && passwordsMatch
    }
    
    /// Returns a validation error message if applicable
    private var validationMessage: String? {
        if !newPassword.isEmpty && newPassword.count < 6 {
            return "Password must be at least 6 characters"
        }
        if !confirmPassword.isEmpty && newPassword != confirmPassword {
            return "Passwords do not match"
        }
        return nil
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                if showSuccess {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Set New Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showSuccess {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(.secondary)
                    }
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
                    // New password field
                    passwordField(
                        title: "New Password",
                        placeholder: "Enter new password",
                        text: $newPassword,
                        icon: "lock.fill"
                    )
                    
                    // Confirm password field
                    passwordField(
                        title: "Confirm Password",
                        placeholder: "Re-enter new password",
                        text: $confirmPassword,
                        icon: "lock.shield.fill"
                    )
                    
                    // Password requirements hint
                    passwordRequirementsHint
                    
                    // Validation error
                    if let message = validationMessage {
                        validationErrorView(message)
                    }
                    
                    // Save button
                    saveButton
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
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(AppColors.success)
            }
            .scaleEffect(hasAppeared ? 1 : 0.5)
            
            VStack(spacing: AppSpacing.md) {
                Text("Password Updated!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
                
                Text("Your password has been changed successfully. You can now sign in with your new password.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.lg)
            }
            
            Spacer()
            
            // Continue button
            Button {
                onSuccess?()
                dismiss()
            } label: {
                Text("Continue to Login")
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
                
                Image(systemName: "lock.rotation")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            Text("Create New Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)
            
            Text("Enter a new password for your account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// Reusable password field component
    private func passwordField(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .frame(width: 20)
                
                SecureField(placeholder, text: text)
                    .textContentType(.none)
            }
            .padding(AppSpacing.md)
            .background(AppColors.groupedBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
    }
    
    /// Password requirements hint
    private var passwordRequirementsHint: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "info.circle.fill")
                .font(.caption2)
            Text("Password must be at least 6 characters")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Validation error message view
    private func validationErrorView(_ message: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.caption)
            Text(message)
                .font(.caption)
        }
        .foregroundStyle(AppColors.error)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.error.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
    }
    
    /// Save new password button
    private var saveButton: some View {
        Button {
            Task {
                await updatePassword()
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    Text("Set New Password")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(isFormValid && !isLoading ? AppColors.primary : Color.gray.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .disabled(!isFormValid || isLoading)
        .animation(AppAnimation.smooth, value: isFormValid)
    }
    
    // MARK: - Actions
    
    /// Updates the password using the reset token from the deep link
    private func updatePassword() async {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use session view model to update password
            // The token from the deep link is already handled by Supabase session
            try await session.updatePassword(newPassword: newPassword)
            
            // Success
            withAnimation(AppAnimation.spring) {
                showSuccess = true
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    ResetPasswordView()
        .environmentObject(UserSessionViewModel())
}


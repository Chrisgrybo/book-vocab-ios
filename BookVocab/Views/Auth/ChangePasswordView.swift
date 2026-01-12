//
//  ChangePasswordView.swift
//  BookVocab
//
//  View for changing the user's password from within the app.
//  Requires current password verification before allowing update.
//
//  Features:
//  - Current password verification
//  - New password with confirmation
//  - Validation feedback
//  - Network awareness (blocks if offline)
//  - Success/error handling
//

import SwiftUI

/// View for authenticated users to change their password.
/// Requires re-authentication with current password before updating.
struct ChangePasswordView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var networkMonitor: NetworkMonitor
    
    // MARK: - State
    
    /// Current password for verification
    @State private var currentPassword: String = ""
    
    /// New password to set
    @State private var newPassword: String = ""
    
    /// Confirmation of new password
    @State private var confirmPassword: String = ""
    
    /// Loading state during password change
    @State private var isLoading: Bool = false
    
    /// Error message to display
    @State private var errorMessage: String?
    
    /// Success state for showing confirmation
    @State private var showSuccess: Bool = false
    
    /// Controls animation on appear
    @State private var hasAppeared: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates the form inputs
    private var isFormValid: Bool {
        // All fields must be filled
        let hasCurrentPassword = !currentPassword.isEmpty
        let hasNewPassword = !newPassword.isEmpty
        let hasConfirmPassword = !confirmPassword.isEmpty
        
        // New password must be at least 6 characters
        let newPasswordValid = newPassword.count >= 6
        
        // Passwords must match
        let passwordsMatch = newPassword == confirmPassword
        
        // New password must be different from current
        let isDifferent = currentPassword != newPassword
        
        return hasCurrentPassword && hasNewPassword && hasConfirmPassword &&
               newPasswordValid && passwordsMatch && isDifferent
    }
    
    /// Returns a validation error message if applicable
    private var validationMessage: String? {
        if !newPassword.isEmpty && newPassword.count < 6 {
            return "New password must be at least 6 characters"
        }
        if !confirmPassword.isEmpty && newPassword != confirmPassword {
            return "Passwords do not match"
        }
        if !currentPassword.isEmpty && !newPassword.isEmpty && currentPassword == newPassword {
            return "New password must be different from current"
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
                
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        // Header illustration
                        headerSection
                            .padding(.top, AppSpacing.xl)
                        
                        // Offline warning
                        if !networkMonitor.isConnected {
                            offlineWarning
                        }
                        
                        // Form card
                        formCard
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                        
                        Spacer(minLength: AppSpacing.xl)
                    }
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
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
            // Success alert
            .alert("Password Changed", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your password has been updated successfully.")
            }
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
                
                Image(systemName: "key.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.primary)
            }
            
            Text("Change Your Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.primary)
            
            Text("Enter your current password and choose a new one")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// Warning banner when offline
    private var offlineWarning: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            
            Text("Password change requires an internet connection")
                .font(.subheadline)
        }
        .foregroundStyle(.white)
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.orange)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
    
    /// Main form card with password fields
    private var formCard: some View {
        VStack(spacing: AppSpacing.lg) {
            // Current password field
            passwordField(
                title: "Current Password",
                placeholder: "Enter current password",
                text: $currentPassword,
                icon: "lock.fill"
            )
            
            Divider()
                .padding(.vertical, AppSpacing.sm)
            
            // New password field
            passwordField(
                title: "New Password",
                placeholder: "Enter new password",
                text: $newPassword,
                icon: "lock.badge.clock.fill"
            )
            
            // Confirm password field
            passwordField(
                title: "Confirm New Password",
                placeholder: "Re-enter new password",
                text: $confirmPassword,
                icon: "lock.shield.fill"
            )
            
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
    
    /// Save changes button
    private var saveButton: some View {
        Button {
            Task {
                await changePassword()
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    Text("Save Changes")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(canSubmit ? AppColors.primary : Color.gray.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .disabled(!canSubmit)
        .animation(AppAnimation.smooth, value: canSubmit)
    }
    
    /// Whether the form can be submitted
    private var canSubmit: Bool {
        isFormValid && !isLoading && networkMonitor.isConnected
    }
    
    // MARK: - Actions
    
    /// Performs the password change operation
    private func changePassword() async {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Use the session view model to change password
            try await session.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
            
            // Success
            showSuccess = true
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Preview

#Preview {
    ChangePasswordView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(NetworkMonitor.shared)
}



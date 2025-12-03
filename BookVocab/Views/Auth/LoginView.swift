//
//  LoginView.swift
//  BookVocab
//
//  Authentication screen for user login and account creation.
//  Provides email/password authentication via Supabase.
//
//  Features:
//  - Modern UI matching app theme
//  - Email/Password sign up and login
//  - Form validation with error messages
//  - Loading states during authentication
//

import SwiftUI

/// The main authentication view handling login and signup.
///
/// This view:
/// - Toggles between login and create account modes
/// - Validates email and password input
/// - Shows loading indicators during auth operations
/// - Displays error messages in an alert
struct LoginView: View {
    
    // MARK: - Environment
    
    /// Access to the shared user session view model.
    /// This ViewModel handles all authentication logic.
    @EnvironmentObject var session: UserSessionViewModel
    
    // MARK: - State
    
    /// User's email input.
    @State private var email: String = ""
    
    /// User's password input.
    @State private var password: String = ""
    
    /// Confirm password for signup mode (must match password).
    @State private var confirmPassword: String = ""
    
    /// Toggle between login (false) and signup (true) modes.
    @State private var isSignUpMode: Bool = false
    
    /// Controls whether the view has appeared (for animations)
    @State private var hasAppeared: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates that all required fields are properly filled.
    /// For login: email and password must not be empty.
    /// For signup: also requires password confirmation match.
    private var isFormValid: Bool {
        // Basic validation: non-empty fields
        let hasEmail = !email.trimmingCharacters(in: .whitespaces).isEmpty
        let hasPassword = !password.isEmpty
        
        if isSignUpMode {
            // For sign up, passwords must match and be at least 6 characters
            let passwordsMatch = password == confirmPassword
            let passwordLongEnough = password.count >= 6
            return hasEmail && hasPassword && passwordsMatch && passwordLongEnough
        }
        
        return hasEmail && hasPassword
    }
    
    /// Returns a validation error message if the form is invalid.
    /// Used to provide feedback to the user about what's wrong.
    private var validationMessage: String? {
        if isSignUpMode {
            if password.count < 6 && !password.isEmpty {
                return "Password must be at least 6 characters"
            }
            if password != confirmPassword && !confirmPassword.isEmpty {
                return "Passwords do not match"
            }
        }
        return nil
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            AppColors.groupedBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Top spacer for vertical centering
                    Spacer(minLength: 60)
                    
                    // App logo and title
                    headerSection
                        .padding(.bottom, AppSpacing.xxl)
                    
                    // Form card
                    VStack(spacing: AppSpacing.lg) {
                        // Email and password fields
                        formSection
                        
                        // Validation error message
                        if let message = validationMessage {
                            validationErrorView(message)
                        }
                        
                        // Login/Signup button
                        actionButton
                            .padding(.top, AppSpacing.sm)
                    }
                    .padding(AppSpacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                            .fill(AppColors.cardBackground)
                            .shadow(color: AppShadow.card.color, radius: AppShadow.card.radius, x: 0, y: AppShadow.card.y)
                    )
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 20)
                    
                    // Toggle between login and signup
                    toggleModeButton
                        .padding(.top, AppSpacing.xl)
                        .opacity(hasAppeared ? 1 : 0)
                    
                    // Bottom spacer
                    Spacer(minLength: 40)
                }
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
        // Alert for displaying error messages from the ViewModel
        .alert("Error", isPresented: .constant(session.errorMessage != nil)) {
            Button("OK") {
                session.clearError()
            }
        } message: {
            Text(session.errorMessage ?? "")
        }
    }
    
    // MARK: - View Components
    
    /// App logo and welcome text header.
    private var headerSection: some View {
        VStack(spacing: AppSpacing.md) {
            // App icon with decorative background
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.primary)
            }
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .opacity(hasAppeared ? 1 : 0)
            
            // App name
            Text("Book Vocab")
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(AppColors.primary)
            
            // Context-aware subtitle
            Text(isSignUpMode ? "Create your account" : "Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .animation(AppAnimation.smooth, value: isSignUpMode)
    }
    
    /// Email and password input fields section.
    private var formSection: some View {
        VStack(spacing: AppSpacing.md) {
            // Email field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Email")
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
            
            // Password field
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Password")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "lock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    
                    // NOTE: .textContentType(.none) disables AutoFill for testing
                    SecureField("Enter password", text: $password)
                        .textContentType(.none)
                }
                .padding(AppSpacing.md)
                .background(AppColors.groupedBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            
            // Confirm password field (only shown in signup mode)
            if isSignUpMode {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Confirm Password")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                        
                        // NOTE: .textContentType(.none) disables AutoFill for testing
                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.none)
                    }
                    .padding(AppSpacing.md)
                    .background(AppColors.groupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(AppAnimation.smooth, value: isSignUpMode)
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
    
    /// Primary action button for Login or Sign Up.
    private var actionButton: some View {
        Button {
            // Dismiss keyboard before starting auth
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            
            // Perform the appropriate auth action
            Task {
                if isSignUpMode {
                    await session.signUp(email: email, password: password)
                } else {
                    await session.signIn(email: email, password: password)
                }
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                // Show loading spinner or button text
                if session.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: isSignUpMode ? "person.badge.plus" : "arrow.right.circle.fill")
                        .font(.headline)
                    Text(isSignUpMode ? "Create Account" : "Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(isFormValid ? AppColors.primary : Color.gray.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .disabled(!isFormValid || session.isLoading)
        .animation(AppAnimation.smooth, value: isFormValid)
        .animation(AppAnimation.smooth, value: session.isLoading)
    }
    
    /// Button to toggle between login and signup modes.
    private var toggleModeButton: some View {
        Button {
            withAnimation(AppAnimation.smooth) {
                isSignUpMode.toggle()
                // Clear password fields when switching modes for security
                password = ""
                confirmPassword = ""
            }
        } label: {
            HStack(spacing: AppSpacing.xxs) {
                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(.secondary)
                Text(isSignUpMode ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.primary)
            }
            .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView()
        .environmentObject(UserSessionViewModel())
}

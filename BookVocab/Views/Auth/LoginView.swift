//
//  LoginView.swift
//  BookVocab
//
//  Authentication screen for user login and account creation.
//  Provides email/password authentication via Supabase.
//
//  Features:
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // App logo and title
                    headerSection
                    
                    // Email and password fields
                    formSection
                    
                    // Validation error message
                    if let message = validationMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    
                    // Login/Signup button
                    actionButton
                    
                    // Toggle between login and signup
                    toggleModeButton
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
            // Alert for displaying error messages from the ViewModel
            .alert("Error", isPresented: .constant(session.errorMessage != nil)) {
                Button("OK") {
                    session.clearError()
                }
            } message: {
                Text(session.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - View Components
    
    /// App logo and welcome text header.
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App icon - uses SF Symbol for book
            Image(systemName: "book.closed.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            // App name
            Text("Book Vocab")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Context-aware subtitle
            Text(isSignUpMode ? "Create your account" : "Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Email and password input fields section.
    private var formSection: some View {
        VStack(spacing: 16) {
            // Email field with appropriate keyboard and content type
            TextField("Email", text: $email)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
            
            // Password field with secure entry
            SecureField("Password", text: $password)
                .textFieldStyle(.roundedBorder)
                .textContentType(isSignUpMode ? .newPassword : .password)
            
            // Confirm password field (only shown in signup mode)
            if isSignUpMode {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.newPassword)
            }
        }
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
            // Show loading spinner or button text
            if session.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text(isSignUpMode ? "Create Account" : "Sign In")
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(isFormValid ? Color.blue : Color.gray.opacity(0.5))
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .disabled(!isFormValid || session.isLoading)
    }
    
    /// Button to toggle between login and signup modes.
    private var toggleModeButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isSignUpMode.toggle()
                // Clear password fields when switching modes for security
                password = ""
                confirmPassword = ""
            }
        } label: {
            HStack(spacing: 4) {
                Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                    .foregroundStyle(.secondary)
                Text(isSignUpMode ? "Sign In" : "Sign Up")
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
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

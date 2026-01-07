//
//  UserSessionViewModel.swift
//  BookVocab
//
//  ViewModel for managing user authentication and session state.
//  Handles sign up, login, and sign out operations.
//
//  This ViewModel uses Supabase Auth for all authentication operations
//  and publishes the current user state for SwiftUI views to react to.
//

import Foundation
import SwiftUI
import Auth
import Supabase

/// ViewModel responsible for managing user authentication and session state.
///
/// This class:
/// - Handles email/password sign up and login
/// - Manages sign out
/// - Publishes authentication state for reactive UI updates
/// - Automatically checks for existing sessions on initialization
///
/// Usage:
/// ```swift
/// @StateObject private var session = UserSessionViewModel()
///
/// if session.isAuthenticated {
///     HomeView()
/// } else {
///     LoginView()
/// }
/// ```
@MainActor
class UserSessionViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently authenticated Supabase user, nil if not logged in.
    /// This is the raw Supabase User object containing id, email, metadata, etc.
    @Published var currentUser: Auth.User?
    
    /// Convenience property to check if a user is currently authenticated.
    /// Returns true when currentUser is not nil.
    @Published var isAuthenticated: Bool = false
    
    /// Loading state for async operations.
    /// Use this to show loading indicators during auth operations.
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user.
    /// Set when an auth operation fails, nil otherwise.
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    /// Reference to the shared Supabase client for authentication operations.
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }
    
    // MARK: - Initialization
    
    /// Creates a new UserSessionViewModel and checks for an existing session.
    /// If a valid session exists, the user will be automatically logged in.
    init() {
        // Check for existing session when the ViewModel is created
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Checks if there's an existing valid session and restores it.
    /// Called automatically on initialization to persist login state across app launches.
    ///
    /// The Supabase SDK stores sessions in the device keychain, so users
    /// remain logged in even after closing the app.
    func checkExistingSession() async {
        isLoading = true
        
        do {
            // Attempt to get the current session from Supabase
            // This will succeed if a valid, non-expired session exists
            let session = try await supabase.auth.session
            
            // Session exists - update our state
            currentUser = session.user
            isAuthenticated = true
        } catch {
            // No valid session exists - user needs to log in
            // This is expected behavior, not an error to display
            currentUser = nil
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Email/Password Authentication
    
    /// Creates a new user account with email and password.
    ///
    /// After successful sign up, Supabase may require email verification
    /// depending on your project settings. Check your Supabase dashboard
    /// under Authentication > Providers > Email.
    ///
    /// - Parameters:
    ///   - email: The user's email address (must be valid email format)
    ///   - password: The user's password (minimum 6 characters by default)
    func signUp(email: String, password: String) async {
        // Reset any previous error state
        errorMessage = nil
        isLoading = true
        
        do {
            // Call Supabase Auth to create a new user
            // This will create the user in Supabase Auth and return a session
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            // Update our published state with the new user
            // Note: The user might need to verify their email before
            // isAuthenticated should be true, depending on your settings
            currentUser = authResponse.user
            isAuthenticated = true
            
            // Track successful sign up
            if let userId = authResponse.user.id.uuidString as String? {
                AnalyticsService.shared.trackSignUp(userId: userId)
            }
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
            
            // Track sign up failure
            AnalyticsService.shared.track(.signUpFailed, properties: [
                "error": error.localizedDescription
            ])
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            
            // Track sign up failure
            AnalyticsService.shared.track(.signUpFailed, properties: [
                "error": error.localizedDescription
            ])
        }
        
        isLoading = false
    }
    
    /// Signs in an existing user with email and password.
    ///
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    func signIn(email: String, password: String) async {
        // Reset any previous error state
        errorMessage = nil
        isLoading = true
        
        do {
            // Call Supabase Auth to sign in the user
            // This validates credentials and returns a session with access token
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            // Update our published state with the authenticated user
            currentUser = session.user
            isAuthenticated = true
            
            // Track successful login
            AnalyticsService.shared.trackLogin(userId: session.user.id.uuidString)
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
            
            // Track login failure
            AnalyticsService.shared.track(.loginFailed, properties: [
                "error": error.localizedDescription
            ])
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            
            // Track login failure
            AnalyticsService.shared.track(.loginFailed, properties: [
                "error": error.localizedDescription
            ])
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    /// Signs out the current user and clears the session.
    ///
    /// This will:
    /// 1. Invalidate the current session on the Supabase server
    /// 2. Clear the stored session from the device keychain
    /// 3. Reset our local state to logged out
    func signOut() async {
        isLoading = true
        
        do {
            // Tell Supabase to invalidate the current session
            try await supabase.auth.signOut()
            
            // Track logout before clearing state
            AnalyticsService.shared.trackLogout()
            
            // Clear our local state
            currentUser = nil
            isAuthenticated = false
            
        } catch {
            // Even if sign out fails on the server, clear local state
            // This ensures the user can still "log out" locally
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            
            // Still track logout and reset analytics
            AnalyticsService.shared.trackLogout()
            
            currentUser = nil
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Password Management
    
    /// Changes the user's password after verifying the current password.
    ///
    /// This method:
    /// 1. Re-authenticates the user with their current password
    /// 2. Updates to the new password if verification succeeds
    ///
    /// - Parameters:
    ///   - currentPassword: The user's current password for verification
    ///   - newPassword: The new password to set
    /// - Throws: An error if verification fails or password update fails
    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = currentUser?.email else {
            throw PasswordError.noUserEmail
        }
        
        // First, verify the current password by attempting to sign in
        // This ensures the user knows their current password before changing it
        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: currentPassword
            )
        } catch {
            throw PasswordError.incorrectCurrentPassword
        }
        
        // Current password verified, now update to new password
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            
            // Track password change
            AnalyticsService.shared.track(.login, properties: [
                "action": "password_changed"
            ])
            
        } catch let error as AuthError {
            throw PasswordError.updateFailed(mapAuthError(error))
        } catch {
            throw PasswordError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Sends a password reset email to the specified email address.
    ///
    /// The email contains a link that, when clicked, will open the app
    /// and allow the user to set a new password.
    ///
    /// - Parameter email: The email address to send the reset link to
    /// - Throws: An error if the email fails to send
    func sendPasswordResetEmail(to email: String) async throws {
        do {
            // The redirectTo URL should match your app's URL scheme
            // Supabase will append tokens to this URL
            try await supabase.auth.resetPasswordForEmail(
                email,
                redirectTo: URL(string: "bookvocab://reset-password")
            )
            
            // Track password reset request
            AnalyticsService.shared.track(.login, properties: [
                "action": "password_reset_requested"
            ])
            
        } catch let error as AuthError {
            throw PasswordError.resetEmailFailed(mapAuthError(error))
        } catch {
            throw PasswordError.resetEmailFailed(error.localizedDescription)
        }
    }
    
    /// Updates the user's password after clicking a reset link from email.
    ///
    /// This method should be called after the user opens the app via
    /// the password reset deep link. The Supabase SDK handles the token
    /// from the deep link automatically.
    ///
    /// - Parameter newPassword: The new password to set
    /// - Throws: An error if the password update fails
    func updatePassword(newPassword: String) async throws {
        do {
            try await supabase.auth.update(user: UserAttributes(password: newPassword))
            
            // Track password reset completion
            AnalyticsService.shared.track(.login, properties: [
                "action": "password_reset_completed"
            ])
            
            // Sign out after password reset to ensure clean state
            // User will need to log in with new password
            try? await supabase.auth.signOut()
            currentUser = nil
            isAuthenticated = false
            
        } catch let error as AuthError {
            throw PasswordError.updateFailed(mapAuthError(error))
        } catch {
            throw PasswordError.updateFailed(error.localizedDescription)
        }
    }
    
    /// Handles the password reset deep link.
    ///
    /// This should be called when the app is opened via a password reset URL.
    /// It extracts the tokens from the URL and establishes a session.
    ///
    /// - Parameter url: The deep link URL containing reset tokens
    /// - Returns: True if the URL was a valid password reset link
    func handlePasswordResetURL(_ url: URL) async -> Bool {
        // Check if this is a password reset URL
        guard url.scheme == "bookvocab",
              url.host == "reset-password" else {
            return false
        }
        
        do {
            // The Supabase SDK can handle the URL and establish a session
            // with the tokens from the reset email
            _ = try await supabase.auth.session(from: url)
            return true
        } catch {
            errorMessage = "Invalid or expired reset link. Please request a new one."
            return false
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error message.
    /// Call this after the user dismisses an error alert.
    func clearError() {
        errorMessage = nil
    }
    
    /// Maps Supabase AuthError to user-friendly error messages.
    ///
    /// - Parameter error: The AuthError from Supabase
    /// - Returns: A user-friendly error message string
    private func mapAuthError(_ error: AuthError) -> String {
        // Map common auth errors to user-friendly messages
        switch error {
        case .sessionNotFound:
            return "No active session found. Please sign in again."
        default:
            // For other errors, use the localized description
            // These are generally already user-friendly from Supabase
            return error.localizedDescription
        }
    }
}

// MARK: - Password Errors

/// Errors that can occur during password management operations.
enum PasswordError: LocalizedError {
    case noUserEmail
    case incorrectCurrentPassword
    case updateFailed(String)
    case resetEmailFailed(String)
    case weakPassword
    case linkExpired
    
    var errorDescription: String? {
        switch self {
        case .noUserEmail:
            return "Unable to retrieve your email address. Please sign in again."
        case .incorrectCurrentPassword:
            return "The current password you entered is incorrect."
        case .updateFailed(let message):
            return "Failed to update password: \(message)"
        case .resetEmailFailed(let message):
            return "Failed to send reset email: \(message)"
        case .weakPassword:
            return "Password is too weak. Please use at least 6 characters."
        case .linkExpired:
            return "This password reset link has expired. Please request a new one."
        }
    }
}

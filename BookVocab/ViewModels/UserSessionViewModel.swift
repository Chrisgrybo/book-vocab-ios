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
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign up failed: \(error.localizedDescription)"
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
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign in failed: \(error.localizedDescription)"
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
            
            // Clear our local state
            currentUser = nil
            isAuthenticated = false
            
        } catch {
            // Even if sign out fails on the server, clear local state
            // This ensures the user can still "log out" locally
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            currentUser = nil
            isAuthenticated = false
        }
        
        isLoading = false
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

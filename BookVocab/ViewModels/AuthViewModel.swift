//
//  AuthViewModel.swift
//  BookVocab
//
//  ViewModel for managing user authentication state.
//  Handles login, signup, and session management via Supabase.
//

import Foundation
import SwiftUI

/// ViewModel responsible for managing user authentication.
/// Published as an environment object to share auth state across the app.
@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently authenticated user, nil if not logged in.
    @Published var currentUser: User?
    
    /// Indicates whether a user is currently authenticated.
    @Published var isAuthenticated: Bool = false
    
    /// Loading state for async operations.
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user.
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    /// Reference to the Supabase service for authentication.
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    
    /// Creates a new AuthViewModel with optional dependency injection.
    /// - Parameter supabaseService: The Supabase service instance (defaults to shared)
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
        
        // TODO: Check for existing session on app launch
        // Task { await checkExistingSession() }
    }
    
    // MARK: - Authentication Methods
    
    /// Attempts to sign in a user with email and password.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase authentication
        // For now, simulate successful login for scaffolding
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            // Placeholder: Create mock user for testing UI
            currentUser = User(email: email)
            isAuthenticated = true
        } catch {
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Attempts to create a new user account.
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase signup
        // For now, simulate successful signup for scaffolding
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            // Placeholder: Create mock user for testing UI
            currentUser = User(email: email)
            isAuthenticated = true
        } catch {
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Signs out the current user.
    func signOut() async {
        isLoading = true
        
        // TODO: Implement actual Supabase sign out
        currentUser = nil
        isAuthenticated = false
        
        isLoading = false
    }
    
    /// Checks for an existing session on app launch.
    func checkExistingSession() async {
        // TODO: Implement session restoration from Supabase
        // For now, user starts logged out
    }
    
    /// Clears any displayed error message.
    func clearError() {
        errorMessage = nil
    }
}


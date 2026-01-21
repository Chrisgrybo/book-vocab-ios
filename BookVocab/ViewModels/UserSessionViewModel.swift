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
import os.log

/// Logger for UserSessionViewModel
private let logger = Logger(subsystem: "com.bookvocab.app", category: "UserSession")

/// ViewModel responsible for managing user authentication and session state.
///
/// This class:
/// - Handles email/password sign up and login
/// - Manages sign out
/// - Publishes authentication state for reactive UI updates
/// - Automatically checks for existing sessions on initialization
/// - Fetches and caches user profile and settings
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
    
    /// The user's profile data from Supabase.
    @Published var userProfile: UserProfile?
    
    /// The user's settings from Supabase.
    @Published var userSettings: UserSettings?
    
    /// Convenience property to check if a user is currently authenticated.
    /// Returns true when currentUser is not nil.
    @Published var isAuthenticated: Bool = false
    
    /// Loading state for async operations.
    /// Use this to show loading indicators during auth operations.
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user.
    /// Set when an auth operation fails, nil otherwise.
    @Published var errorMessage: String?
    
    // MARK: - Cached Properties (for offline use)
    
    /// Cached premium status for offline use
    @AppStorage("cachedIsPremium") private var cachedIsPremium: Bool = false
    
    /// Cached display name for offline use
    @AppStorage("cachedDisplayName") private var cachedDisplayName: String = ""
    
    /// Cached total books count
    @AppStorage("cachedTotalBooks") private var cachedTotalBooks: Int = 0
    
    /// Cached total words count
    @AppStorage("cachedTotalWords") private var cachedTotalWords: Int = 0
    
    /// Cached mastered words count
    @AppStorage("cachedMasteredWords") private var cachedMasteredWords: Int = 0
    
    /// Cached study sessions count
    @AppStorage("cachedTotalStudySessions") private var cachedTotalStudySessions: Int = 0
    
    // MARK: - Private Properties
    
    /// Reference to the shared Supabase client for authentication operations.
    private var supabase: SupabaseClient {
        SupabaseService.shared.client
    }
    
    /// Reference to the shared Supabase service for database operations.
    private let supabaseService = SupabaseService.shared
    
    /// Network monitor for checking connectivity.
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Initialization
    
    /// Creates a new UserSessionViewModel and checks for an existing session.
    /// If a valid session exists, the user will be automatically logged in.
    init() {
        logger.info("🔐 UserSessionViewModel initialized")
        
        // Check for existing session when the ViewModel is created
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the user is premium (uses cached value if settings not loaded)
    var isPremium: Bool {
        userSettings?.isPremium ?? cachedIsPremium
    }
    
    /// The user's display name (uses cached value if profile not loaded)
    var displayName: String {
        userProfile?.displayNameOrDefault ?? (cachedDisplayName.isEmpty ? "Reader" : cachedDisplayName)
    }
    
    // MARK: - Session Management
    
    /// Checks if there's an existing valid session and restores it.
    /// Called automatically on initialization to persist login state across app launches.
    ///
    /// The Supabase SDK stores sessions in the device keychain, so users
    /// remain logged in even after closing the app.
    func checkExistingSession() async {
        isLoading = true
        logger.info("🔐 Checking for existing session...")
        
        do {
            // Attempt to get the current session from Supabase
            // This will succeed if a valid, non-expired session exists
            let session = try await supabase.auth.session
            
            // Session exists - update our state
            currentUser = session.user
            isAuthenticated = true
            
            logger.info("🔐 Session restored for user: \(session.user.id.uuidString.prefix(8))")
            
            // Fetch profile and settings
            await loadUserData(userId: session.user.id)
            
        } catch {
            // No valid session exists - user needs to log in
            // This is expected behavior, not an error to display
            currentUser = nil
            isAuthenticated = false
            userProfile = nil
            userSettings = nil
            
            logger.debug("🔐 No existing session found")
        }
        
        isLoading = false
    }
    
    /// Loads user profile and settings from Supabase.
    /// Falls back to cached data if offline.
    /// - Parameter userId: The user's UUID
    private func loadUserData(userId: UUID) async {
        logger.info("👤 Loading user data for: \(userId.uuidString.prefix(8))")
        
        // Check if we're online
        guard networkMonitor.isConnected else {
            logger.warning("👤 Offline - using cached user data")
            loadCachedUserData()
            return
        }
        
        // Fetch profile
        do {
            if let profile = try await supabaseService.fetchUserProfile(for: userId) {
                userProfile = profile
                cacheUserProfile(profile)
                logger.info("👤 Profile loaded: \(profile.displayNameOrDefault)")
            } else {
                // Profile doesn't exist - create it
                logger.info("👤 Profile not found - creating...")
                try await createUserProfile(userId: userId)
            }
        } catch {
            logger.error("👤 Failed to fetch profile: \(error.localizedDescription)")
            loadCachedUserData()
        }
        
        // Fetch settings
        do {
            if let settings = try await supabaseService.fetchUserSettings(for: userId) {
                userSettings = settings
                cacheUserSettings(settings)
                logger.info("👤 Settings loaded: premium=\(settings.isPremium)")
            } else {
                // Settings don't exist - create them
                logger.info("👤 Settings not found - creating...")
                try await createUserSettings(userId: userId)
            }
        } catch {
            logger.error("👤 Failed to fetch settings: \(error.localizedDescription)")
            loadCachedUserData()
        }
    }
    
    /// Creates a new user profile in Supabase.
    private func createUserProfile(userId: UUID) async throws {
        let displayName = currentUser?.email?.components(separatedBy: "@").first
        let insert = UserProfileInsert(userId: userId, displayName: displayName)
        
        try await supabaseService.createUserProfile(insert)
        
        // Fetch the created profile
        if let profile = try await supabaseService.fetchUserProfile(for: userId) {
            userProfile = profile
            cacheUserProfile(profile)
        }
    }
    
    /// Creates new user settings in Supabase.
    private func createUserSettings(userId: UUID) async throws {
        let insert = UserSettingsInsert(userId: userId)
        
        try await supabaseService.createUserSettings(insert)
        
        // Fetch the created settings
        if let settings = try await supabaseService.fetchUserSettings(for: userId) {
            userSettings = settings
            cacheUserSettings(settings)
        }
    }
    
    /// Caches user profile data for offline use.
    private func cacheUserProfile(_ profile: UserProfile) {
        cachedDisplayName = profile.displayName ?? ""
        cachedTotalBooks = profile.totalBooks
        cachedTotalWords = profile.totalWords
        cachedMasteredWords = profile.masteredWords
        cachedTotalStudySessions = profile.totalStudySessions
        logger.debug("👤 Profile cached")
    }
    
    /// Caches user settings for offline use.
    private func cacheUserSettings(_ settings: UserSettings) {
        cachedIsPremium = settings.isPremium
        logger.debug("👤 Settings cached")
    }
    
    /// Loads cached user data when offline.
    private func loadCachedUserData() {
        // Create a temporary profile from cached data
        if let userId = currentUser?.id {
            userProfile = UserProfile(
                userId: userId,
                displayName: cachedDisplayName.isEmpty ? nil : cachedDisplayName,
                totalBooks: cachedTotalBooks,
                totalWords: cachedTotalWords,
                masteredWords: cachedMasteredWords,
                totalStudySessions: cachedTotalStudySessions
            )
            
            userSettings = UserSettings(
                userId: userId,
                isPremium: cachedIsPremium
            )
        }
        logger.info("👤 Loaded cached user data")
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
        
        logger.info("🔐 Starting sign up for: \(email)")
        
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
            
            logger.info("🔐 Sign up successful for user: \(authResponse.user.id.uuidString.prefix(8))")
            
            // Create user profile and settings
            let userId = authResponse.user.id
            let displayName = email.components(separatedBy: "@").first
            
            do {
                // Create profile
                let profileInsert = UserProfileInsert(userId: userId, displayName: displayName)
                try await supabaseService.createUserProfile(profileInsert)
                
                // Create settings
                let settingsInsert = UserSettingsInsert(userId: userId)
                try await supabaseService.createUserSettings(settingsInsert)
                
                // Load the created data
                await loadUserData(userId: userId)
                
                logger.info("🔐 Profile and settings created for new user")
            } catch {
                logger.error("🔐 Failed to create profile/settings: \(error.localizedDescription)")
                // Continue anyway - profile/settings can be created on next login
            }
            
            // Track successful sign up
            AnalyticsService.shared.trackSignUp(userId: userId.uuidString)
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
            
            logger.error("🔐 Sign up failed: \(error.localizedDescription)")
            
            // Track sign up failure
            AnalyticsService.shared.track(.signUpFailed, properties: [
                "error": error.localizedDescription
            ])
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign up failed: \(error.localizedDescription)"
            
            logger.error("🔐 Sign up failed: \(error.localizedDescription)")
            
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
        
        logger.info("🔐 Starting sign in for: \(email)")
        
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
            
            logger.info("🔐 Sign in successful for user: \(session.user.id.uuidString.prefix(8))")
            
            // Load profile and settings
            await loadUserData(userId: session.user.id)
            
            // Track successful login
            AnalyticsService.shared.trackLogin(userId: session.user.id.uuidString)
            
        } catch let error as AuthError {
            // Handle Supabase-specific auth errors with user-friendly messages
            errorMessage = mapAuthError(error)
            
            logger.error("🔐 Sign in failed: \(error.localizedDescription)")
            
            // Track login failure
            AnalyticsService.shared.track(.loginFailed, properties: [
                "error": error.localizedDescription
            ])
        } catch {
            // Handle any other unexpected errors
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            
            logger.error("🔐 Sign in failed: \(error.localizedDescription)")
            
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
        logger.info("🔐 Signing out...")
        
        do {
            // Tell Supabase to invalidate the current session
            try await supabase.auth.signOut()
            
            // Track logout before clearing state
            AnalyticsService.shared.trackLogout()
            
            // Clear our local state
            clearUserState()
            
            logger.info("🔐 Sign out successful")
            
        } catch {
            // Even if sign out fails on the server, clear local state
            // This ensures the user can still "log out" locally
            errorMessage = "Sign out failed: \(error.localizedDescription)"
            
            logger.error("🔐 Sign out failed on server, clearing local state anyway")
            
            // Still track logout and reset analytics
            AnalyticsService.shared.trackLogout()
            
            clearUserState()
        }
        
        isLoading = false
    }
    
    /// Clears all user state (called on sign out).
    private func clearUserState() {
        currentUser = nil
        isAuthenticated = false
        userProfile = nil
        userSettings = nil
        
        // Note: We keep cached data for faster loading if user logs back in
        // Clear cache explicitly if needed with clearCachedData()
    }
    
    /// Clears all cached user data.
    func clearCachedData() {
        cachedDisplayName = ""
        cachedIsPremium = false
        cachedTotalBooks = 0
        cachedTotalWords = 0
        cachedMasteredWords = 0
        cachedTotalStudySessions = 0
        logger.info("👤 Cached data cleared")
    }
    
    // MARK: - Profile & Settings Updates
    
    /// Updates the user's display name.
    /// - Parameter displayName: The new display name
    func updateDisplayName(_ displayName: String) async throws {
        guard let userId = currentUser?.id else {
            logger.warning("👤 Cannot update display name - no user")
            return
        }
        
        logger.info("👤 Updating display name to: \(displayName)")
        
        try await supabaseService.updateUserProfile(userId: userId, displayName: displayName)
        
        // Update local state
        userProfile?.displayName = displayName
        cachedDisplayName = displayName
        
        logger.info("👤 Display name updated")
    }
    
    /// Updates user settings.
    /// - Parameter update: The settings fields to update
    func updateSettings(_ update: UserSettingsUpdate) async throws {
        guard let userId = currentUser?.id else {
            logger.warning("⚙️ Cannot update settings - no user")
            return
        }
        
        logger.info("⚙️ Updating user settings")
        
        try await supabaseService.updateUserSettings(userId: userId, update: update)
        
        // Refresh settings from server
        if let settings = try await supabaseService.fetchUserSettings(for: userId) {
            userSettings = settings
            cacheUserSettings(settings)
        }
        
        logger.info("⚙️ Settings updated")
    }
    
    /// Updates the preferred study mode.
    /// - Parameter mode: The study mode preference
    func updatePreferredStudyMode(_ mode: String) async throws {
        var update = UserSettingsUpdate()
        update.preferredStudyMode = mode
        try await updateSettings(update)
    }
    
    /// Updates notification settings.
    /// - Parameters:
    ///   - enabled: Whether notifications are enabled
    ///   - reminderTime: Daily reminder time (HH:mm format)
    func updateNotificationSettings(enabled: Bool, reminderTime: String? = nil) async throws {
        var update = UserSettingsUpdate()
        update.notificationsEnabled = enabled
        if let time = reminderTime {
            update.dailyReminderTime = time
        }
        try await updateSettings(update)
    }
    
    /// Refreshes user data from the server.
    func refreshUserData() async {
        guard let userId = currentUser?.id else { return }
        await loadUserData(userId: userId)
    }
    
    /// Increments a profile stat and syncs to server.
    /// - Parameters:
    ///   - stat: The stat to increment (total_books, total_words, mastered_words, total_study_sessions)
    ///   - amount: Amount to increment by (default 1)
    func incrementProfileStat(_ stat: String, by amount: Int = 1) async {
        guard let userId = currentUser?.id else { return }
        
        // Update local state immediately
        switch stat {
        case "total_books":
            userProfile?.totalBooks += amount
            cachedTotalBooks += amount
        case "total_words":
            userProfile?.totalWords += amount
            cachedTotalWords += amount
        case "mastered_words":
            userProfile?.masteredWords += amount
            cachedMasteredWords += amount
        case "total_study_sessions":
            userProfile?.totalStudySessions += amount
            cachedTotalStudySessions += amount
        default:
            break
        }
        
        // Sync to server if online
        if networkMonitor.isConnected {
            do {
                try await supabaseService.incrementUserProfileStat(userId: userId, stat: stat, amount: amount)
            } catch {
                logger.error("👤 Failed to sync stat increment: \(error.localizedDescription)")
            }
        }
    }
    
    /// Decrements a profile stat (for deletions).
    func decrementProfileStat(_ stat: String, by amount: Int = 1) async {
        await incrementProfileStat(stat, by: -amount)
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

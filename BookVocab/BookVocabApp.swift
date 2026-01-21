//
//  BookVocabApp.swift
//  BookVocab
//
//  Main entry point for the Read & Recall iOS application.
//  This app helps users track vocabulary words from books they read.
//
//  Architecture:
//  - Uses MVVM pattern with SwiftUI
//  - UserSessionViewModel manages authentication state
//  - Environment objects share state across the view hierarchy
//  - Supabase provides backend authentication and database
//  - Core Data provides offline caching
//  - AdMob provides monetization (MREC banners + interstitials)
//  - Mixpanel provides analytics tracking
//

import SwiftUI
import GoogleMobileAds

/// The main application struct that serves as the entry point for Read & Recall.
///
/// This struct:
/// - Creates and owns the shared ViewModels as @StateObject
/// - Initializes offline caching services
/// - Initializes AdMob SDK for monetization
/// - Handles deep links for password reset
/// - Determines which view to show based on authentication state
/// - Injects ViewModels into the environment for child views
@main
struct BookVocabApp: App {
    
    // MARK: - State Objects
    
    /// The user session view model managing authentication state.
    /// This is the source of truth for whether the user is logged in.
    /// Created as @StateObject to survive view updates.
    @StateObject private var session = UserSessionViewModel()
    
    /// Whether a password reset deep link was detected
    @State private var showPasswordReset: Bool = false
    
    /// Shared books view model for managing the user's book collection.
    @StateObject private var booksViewModel = BooksViewModel()
    
    /// Shared vocab view model for managing vocabulary words.
    @StateObject private var vocabViewModel = VocabViewModel()
    
    /// Network monitor for tracking online/offline status.
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    /// Sync service for managing data synchronization.
    @StateObject private var syncService = SyncService.shared
    
    /// Ad manager for handling AdMob ads.
    @StateObject private var adManager = AdManager.shared
    
    /// Analytics service for tracking user behavior.
    @StateObject private var analytics = AnalyticsService.shared
    
    // MARK: - Initialization
    
    init() {
        // Initialize persistence controller to set up Core Data stack
        _ = PersistenceController.shared
        
        // Initialize Google Mobile Ads SDK
        // This must be called before loading any ads
        AdManager.shared.initialize()
        
        // Initialize Mixpanel Analytics
        // Uses Secrets.mixpanelToken - events are queued offline if network unavailable
        AnalyticsService.shared.initialize()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            // Root view that switches between login and main app
            // based on authentication state
            Group {
                if session.isAuthenticated {
                    // User is logged in - check if onboarding is needed
                    // Only show onboarding if settings have loaded and confirm it's needed
                    if session.userSettings != nil && !session.userSettings!.hasCompletedOnboarding {
                        // Show onboarding for new users who haven't completed it
                        OnboardingView(onComplete: {
                            // Settings will update automatically, triggering re-render
                        })
                        .environmentObject(session)
                        .transition(.opacity)
                    } else {
                        // User completed onboarding OR settings still loading - show main app
                        MainTabView()
                            .environmentObject(session)
                            .environmentObject(booksViewModel)
                            .environmentObject(vocabViewModel)
                            .environmentObject(networkMonitor)
                            .environmentObject(syncService)
                            .transition(.opacity)
                    }
                } else {
                    // User is not logged in - show login screen
                    LoginView()
                        .environmentObject(session)
                }
            }
            .onAppear {
                setupOnAppear()
            }
            .onChange(of: session.currentUser?.id) { _, newUserId in
                handleUserChange(newUserId: newUserId)
            }
            // Show loading overlay while checking for existing session
            .overlay {
                if session.isLoading && !session.isAuthenticated {
                    // Initial session check loading state
                    ZStack {
                        Color(.systemBackground)
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading...")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            // Show offline banner when not connected
            .overlay(alignment: .top) {
                if !networkMonitor.isConnected {
                    OfflineBanner()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: networkMonitor.isConnected)
            // Handle deep links for password reset
            .onOpenURL { url in
                handleDeepLink(url)
            }
            // Show password reset sheet when deep link detected
            .sheet(isPresented: $showPasswordReset) {
                ResetPasswordView(onSuccess: {
                    // After successful password reset, user needs to log in again
                    showPasswordReset = false
                })
                .environmentObject(session)
            }
        }
    }
    
    // MARK: - Lifecycle
    
    /// Called when the app appears - sets up user session if authenticated.
    private func setupOnAppear() {
        guard session.isAuthenticated, let userId = session.currentUser?.id else { return }
        
        setupViewModels(userId: userId)
        
        // Identify user for analytics
        AnalyticsService.shared.identify(userId: userId.uuidString)
        
        // Set user ID on subscription manager
        SubscriptionManager.shared.setUserId(userId)
        
        // Load premium status from backend if available
        if let settings = session.userSettings {
            SubscriptionManager.shared.loadPremiumStatusFromBackend(settings)
        }
        
        // Fetch data on app launch to ensure consistency
        Task {
            await loadUserData()
        }
    }
    
    /// Handles user ID changes (login/logout).
    private func handleUserChange(newUserId: UUID?) {
        if let userId = newUserId {
            setupViewModels(userId: userId)
            SubscriptionManager.shared.setUserId(userId)
            
            if let settings = session.userSettings {
                SubscriptionManager.shared.loadPremiumStatusFromBackend(settings)
            }
            
            Task {
                await loadUserData()
            }
        } else {
            // User logged out - clear subscription manager user ID
            SubscriptionManager.shared.clearUserId()
        }
    }
    
    // MARK: - Setup
    
    /// Sets up ViewModels with user ID and stats callbacks.
    /// - Parameter userId: The current user's ID
    private func setupViewModels(userId: UUID) {
        // Set user IDs
        booksViewModel.setUserId(userId)
        vocabViewModel.setUserId(userId)
        
        // Connect stats callbacks to session's profile stats
        booksViewModel.onStatsChanged = { [weak session] stat, amount in
            Task { @MainActor in
                if amount > 0 {
                    await session?.incrementProfileStat(stat, by: amount)
                } else {
                    await session?.decrementProfileStat(stat, by: -amount)
                }
            }
        }
        
        vocabViewModel.onStatsChanged = { [weak session] stat, amount in
            Task { @MainActor in
                if amount > 0 {
                    await session?.incrementProfileStat(stat, by: amount)
                } else {
                    await session?.decrementProfileStat(stat, by: -amount)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// Loads user data (books and vocab words) on app launch.
    /// Ensures data is fetched from cache first, then synced with backend.
    private func loadUserData() async {
        // Fetch books and vocab words in parallel
        async let booksTask: () = booksViewModel.fetchBooks()
        async let vocabTask: () = vocabViewModel.fetchAllWords()
        
        // Wait for both to complete
        await booksTask
        await vocabTask
    }
    
    // MARK: - Deep Link Handling
    
    /// Handles incoming deep links for password reset.
    /// - Parameter url: The URL the app was opened with
    private func handleDeepLink(_ url: URL) {
        Task {
            // Check if this is a password reset deep link
            let isPasswordReset = await session.handlePasswordResetURL(url)
            
            if isPasswordReset {
                // Show the password reset view
                await MainActor.run {
                    showPasswordReset = true
                }
            }
        }
    }
}

// MARK: - Offline Banner

/// A banner displayed when the app is offline.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
            
            Text("Offline Mode")
                .font(.caption)
                .fontWeight(.medium)
            
            Text("Changes will sync when online")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.9))
        .foregroundStyle(.white)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .padding(.top, 50) // Account for safe area
    }
}

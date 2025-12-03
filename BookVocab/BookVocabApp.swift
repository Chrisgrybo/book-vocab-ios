//
//  BookVocabApp.swift
//  BookVocab
//
//  Main entry point for the Book Vocab iOS application.
//  This app helps users track vocabulary words from books they read.
//
//  Architecture:
//  - Uses MVVM pattern with SwiftUI
//  - UserSessionViewModel manages authentication state
//  - Environment objects share state across the view hierarchy
//  - Supabase provides backend authentication and database
//  - Core Data provides offline caching
//  - AdMob provides monetization (MREC banners + interstitials)
//

import SwiftUI
import GoogleMobileAds

/// The main application struct that serves as the entry point for Book Vocab.
///
/// This struct:
/// - Creates and owns the shared ViewModels as @StateObject
/// - Initializes offline caching services
/// - Initializes AdMob SDK for monetization
/// - Determines which view to show based on authentication state
/// - Injects ViewModels into the environment for child views
@main
struct BookVocabApp: App {
    
    // MARK: - State Objects
    
    /// The user session view model managing authentication state.
    /// This is the source of truth for whether the user is logged in.
    /// Created as @StateObject to survive view updates.
    @StateObject private var session = UserSessionViewModel()
    
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
    
    // MARK: - Initialization
    
    init() {
        // Initialize persistence controller to set up Core Data stack
        _ = PersistenceController.shared
        
        // Initialize Google Mobile Ads SDK
        // This must be called before loading any ads
        AdManager.shared.initialize()
    }
    
    // MARK: - Body
    
    var body: some Scene {
        WindowGroup {
            // Root view that switches between login and main app
            // based on authentication state
            Group {
                if session.isAuthenticated {
                    // User is logged in - show the main app with tab navigation
                    MainTabView()
                        .environmentObject(session)
                        .environmentObject(booksViewModel)
                        .environmentObject(vocabViewModel)
                        .environmentObject(networkMonitor)
                        .environmentObject(syncService)
                        .onAppear {
                            // Set user ID for fetching user-specific data
                            if let userId = session.currentUser?.id {
                                booksViewModel.setUserId(userId)
                            }
                        }
                } else {
                    // User is not logged in - show login screen
                    LoginView()
                        .environmentObject(session)
                }
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

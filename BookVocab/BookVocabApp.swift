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
//

import SwiftUI

/// The main application struct that serves as the entry point for Book Vocab.
///
/// This struct:
/// - Creates and owns the shared ViewModels as @StateObject
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
    /// Will be used once we implement database functionality.
    @StateObject private var booksViewModel = BooksViewModel()
    
    /// Shared vocab view model for managing vocabulary words.
    /// Will be used once we implement database functionality.
    @StateObject private var vocabViewModel = VocabViewModel()
    
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
        }
    }
}

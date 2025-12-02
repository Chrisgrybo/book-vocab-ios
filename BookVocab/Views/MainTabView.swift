//
//  MainTabView.swift
//  BookVocab
//
//  Main navigation container using TabView.
//  Provides access to Home, All Words, and Study sections.
//

import SwiftUI

/// The main tab-based navigation container for the app.
/// Contains tabs for Home (Books), All Vocab Words, and Study Section.
struct MainTabView: View {
    
    // MARK: - Environment
    
    /// Access to the shared user session view model.
    @EnvironmentObject var session: UserSessionViewModel
    
    /// Access to the shared books view model.
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// Currently selected tab index.
    @State private var selectedTab: Int = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab - Book List
            HomeView()
                .tabItem {
                    Label("Books", systemImage: "book.fill")
                }
                .tag(0)
            
            // All Vocab Words Tab
            AllVocabView()
                .tabItem {
                    Label("All Words", systemImage: "textformat.abc")
                }
                .tag(1)
            
            // Study Section Tab
            StudyView()
                .tabItem {
                    Label("Study", systemImage: "brain.head.profile")
                }
                .tag(2)
        }
        .tint(.blue)
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
        .environmentObject(VocabViewModel())
}

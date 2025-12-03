//
//  MainTabView.swift
//  BookVocab
//
//  Main navigation container with polished tab bar.
//  Provides access to Home, All Words, and Study sections.
//
//  Features:
//  - Clean tab bar design
//  - Consistent SF Symbols
//  - Gradient accent color
//

import SwiftUI

struct MainTabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    @State private var selectedTab: Tab = .books
    
    enum Tab: Int, CaseIterable {
        case books = 0
        case words = 1
        case study = 2
        
        var title: String {
            switch self {
            case .books: return "Library"
            case .words: return "Words"
            case .study: return "Study"
            }
        }
        
        var icon: String {
            switch self {
            case .books: return "books.vertical.fill"
            case .words: return "textformat.abc"
            case .study: return "brain.head.profile"
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Books tab
            HomeView()
                .tabItem {
                    Label(Tab.books.title, systemImage: Tab.books.icon)
                }
                .tag(Tab.books)
            
            // Words tab
            AllVocabView()
                .tabItem {
                    Label(Tab.words.title, systemImage: Tab.words.icon)
                }
                .tag(Tab.words)
            
            // Study tab
            StudyView()
                .tabItem {
                    Label(Tab.study.title, systemImage: Tab.study.icon)
                }
                .tag(Tab.study)
        }
        .tint(AppColors.primary)
        .onAppear {
            // Configure tab bar appearance
            configureTabBarAppearance()
        }
    }
    
    // MARK: - Tab Bar Appearance
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Tan background
        appearance.backgroundColor = UIColor(AppColors.tan)
        
        // Selected item color - Black
        let selectedColor = UIColor.black
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: selectedColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Unselected item color
        let normalColor = UIColor.secondaryLabel
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
        .environmentObject(VocabViewModel())
}

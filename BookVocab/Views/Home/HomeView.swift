//
//  HomeView.swift
//  BookVocab
//
//  Main home screen displaying the user's book collection.
//  Premium design inspired by Apple Books + Goodreads.
//
//  Features:
//  - Beautiful gradient header with stats
//  - Book grid with large cover images
//  - Smooth animations and transitions
//  - Pull to refresh
//

import SwiftUI
import os.log

/// Logger for HomeView debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "HomeView")

/// The home screen showing a list of the user's books.
///
/// Premium design with:
/// - Gradient header with vocabulary stats
/// - Beautiful book cards with cover images
/// - Smooth appear animations
/// - Clean, spacious layout
struct HomeView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - State
    
    @State private var showingAddBook: Bool = false
    @State private var searchText: String = ""
    @State private var hasAppeared: Bool = false
    @State private var bookToDelete: Book?
    @State private var showDeleteConfirmation: Bool = false
    @State private var showDeleteError: Bool = false
    @State private var deleteErrorMessage: String = ""
    @State private var showUpgradeModal: Bool = false
    
    // MARK: - Computed Properties
    
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return booksViewModel.books
        }
        return booksViewModel.books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var userDisplayName: String {
        if let email = session.currentUser?.email {
            return String(email.split(separator: "@").first ?? "Reader")
        }
        return "Reader"
    }
    
    private var totalWords: Int { vocabViewModel.totalWordCount }
    private var masteredWords: Int { vocabViewModel.masteredCount }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if booksViewModel.books.isEmpty {
                    ScrollView {
                        VStack(spacing: 0) {
                            headerSection
                            emptyStateView
                                .padding(.top, AppSpacing.xxxl)
                        }
                    }
                } else {
                    List {
                        // Header section
                        Section {
                            headerSection
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Books section with swipe actions
                        Section {
                            booksListContent
                        } header: {
                            HStack {
                                Text("My Library")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("\(filteredBooks.count) books")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                            .padding(.vertical, AppSpacing.sm)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.horizontalPadding, bottom: 4, trailing: AppSpacing.horizontalPadding))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppColors.groupedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .searchable(text: $searchText, prompt: "Search books...")
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .onChange(of: showingAddBook) { _, isShowing in
                // Force refresh when sheet closes
                if !isShowing {
                    // Trigger view update by toggling a state
                    Task { @MainActor in
                        // Small delay to ensure book is saved
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                        booksViewModel.objectWillChange.send()
                    }
                }
            }
            // Upgrade modal for free tier limits
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeView(reason: subscriptionManager.upgradeReason)
            }
            // Delete confirmation dialog
            .confirmationDialog(
                "Delete Book",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Book & Words", role: .destructive) {
                    if let book = bookToDelete {
                        Task {
                            await deleteBook(book, deleteWords: true)
                        }
                    }
                }
                Button("Delete Book Only", role: .destructive) {
                    if let book = bookToDelete {
                        Task {
                            await deleteBook(book, deleteWords: false)
                        }
                    }
                }
                Button("Cancel", role: .cancel) {
                    bookToDelete = nil
                }
            } message: {
                if let book = bookToDelete {
                    let wordCount = vocabViewModel.fetchWords(forBook: book.id).count
                    if wordCount > 0 {
                        Text("This book has \(wordCount) vocabulary words. Would you like to delete them too?")
                    } else {
                        Text("Are you sure you want to delete \"\(book.title)\"?")
                    }
                }
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .refreshable {
                await booksViewModel.fetchBooks()
                await vocabViewModel.fetchAllWords()
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // Greeting
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Hello, \(userDisplayName)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Keep building your vocabulary")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.top, AppSpacing.md)
            
            // Stats card
            statsCard
                .padding(.horizontal, AppSpacing.horizontalPadding)
        }
        .padding(.bottom, AppSpacing.lg)
        .background(AppColors.groupedBackground)
    }
    
    private var statsCard: some View {
        HStack(spacing: 0) {
            StatDisplay("\(totalWords)", label: "Words", icon: "textformat.abc", color: .blue)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 50)
            
            StatDisplay("\(masteredWords)", label: "Mastered", icon: "checkmark.circle.fill", color: AppColors.success)
            
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1, height: 50)
            
            StatDisplay("\(totalWords - masteredWords)", label: "Learning", icon: "book.fill", color: AppColors.warning)
        }
        .padding(.vertical, AppSpacing.md)
        .cardStyle(cornerRadius: AppRadius.large)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Books List Content (with swipe actions)
    
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    @ViewBuilder
    private var booksListContent: some View {
        ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
            // Each book row as a NavigationLink with hidden chevron
            BookRowView(
                book: book,
                hasAppeared: hasAppeared,
                animationDelay: Double(index) * 0.05,
                onDelete: {
                    bookToDelete = book
                    showDeleteConfirmation = true
                }
            )
            
            // Insert MREC ad every 5 books
            if shouldShowAdInHome(at: index) {
                AdMRECView()
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            }
        }
    }
    
    /// Determines if an ad should be shown after the given index.
    private func shouldShowAdInHome(at index: Int) -> Bool {
        guard !isPremium else { return false }
        guard filteredBooks.count >= 5 else { return false }
        guard index < filteredBooks.count - 1 else { return false }
        return (index + 1) % 5 == 0
    }
    
    // MARK: - Actions
    
    /// Deletes a book with optional associated words deletion.
    private func deleteBook(_ book: Book, deleteWords: Bool) async {
        logger.info("📚 Deleting book: '\(book.title)', deleteWords: \(deleteWords)")
        
        withAnimation(AppAnimation.spring) {
            // Delete associated words if requested
            if deleteWords {
                Task {
                    await vocabViewModel.deleteWords(forBook: book.id)
                }
            }
            
            // Delete the book
            Task {
                await booksViewModel.deleteBook(book)
            }
        }
        
        // Check for errors
        if let error = booksViewModel.errorMessage {
            deleteErrorMessage = error
            showDeleteError = true
        }
        
        bookToDelete = nil
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            // Illustration
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("Start Your Journey")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add your first book and begin\nbuilding your vocabulary.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddBook = true
            } label: {
                Label("Add Your First Book", systemImage: "plus")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, AppSpacing.xxxl)
        }
        .padding(AppSpacing.xl)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
    }
    
    // MARK: - Toolbar Items
    
    private var addButton: some View {
        Button {
            // Check book limit for free users
            if subscriptionManager.canAddBook(currentCount: booksViewModel.books.count) {
                showingAddBook = true
            } else {
                subscriptionManager.promptUpgrade(reason: .bookLimit)
                showUpgradeModal = true
            }
        } label: {
            Image(systemName: "plus")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AppColors.primary)
                .clipShape(Circle())
        }
    }
    
    // MARK: - Free Tier Limit Display
    
    private var bookLimitIndicator: some View {
        Group {
            if !subscriptionManager.isPremium {
                LimitIndicator(
                    current: booksViewModel.books.count,
                    max: FreemiumLimits.maxBooks,
                    label: "Books"
                )
                .padding(.horizontal, AppSpacing.horizontalPadding)
                .padding(.top, AppSpacing.sm)
            }
        }
    }
}

// MARK: - Book Card View

/// A premium book card with cover, title, author, and progress.
struct BookCardView: View {
    let book: Book
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    private var bookWords: [VocabWord] {
        vocabViewModel.fetchWords(forBook: book.id)
    }
    
    private var wordCount: Int { bookWords.count }
    private var masteredCount: Int { bookWords.filter { $0.mastered }.count }
    private var progress: Double {
        guard wordCount > 0 else { return 0 }
        return Double(masteredCount) / Double(wordCount)
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Book cover
            bookCover
            
            // Book info
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(book.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                Spacer(minLength: AppSpacing.xs)
                
                // Stats row - always show both stats for consistent layout
                HStack(spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "textformat.abc")
                            .font(.caption)
                        Text("\(wordCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.blue)
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("\(masteredCount)")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppColors.success)
                    .opacity(masteredCount > 0 ? 1 : 0.3)
                }
                
                // Progress bar - always show for consistent height
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 4)
                        
                        Capsule()
                            .fill(AppColors.greenGradient)
                            .frame(width: geo.size.width * progress, height: 4)
                    }
                }
                .frame(height: 4)
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 110)
        .cardStyle(padding: AppSpacing.md)
    }
    
    private var bookCover: some View {
        Group {
            if let coverUrl = book.coverImageUrl, !coverUrl.isEmpty, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        coverPlaceholder
                    case .empty:
                        coverPlaceholder
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    @unknown default:
                        coverPlaceholder
                    }
                }
            } else {
                coverPlaceholder
            }
        }
        .frame(width: 70, height: 100)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var coverPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.tanDark, AppColors.tan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary.opacity(0.5))
                
                Text(book.title.prefix(8))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AppColors.primary.opacity(0.4))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Book Row View (Individual swipe handling)

/// A single book row with navigation and swipe-to-delete.
/// Each row handles its own swipe state independently.
struct BookRowView: View {
    let book: Book
    let hasAppeared: Bool
    let animationDelay: Double
    let onDelete: () -> Void
    
    var body: some View {
        // NavigationLink with hidden chevron using ZStack overlay technique
        ZStack {
            // Hidden NavigationLink for navigation
            NavigationLink(destination: BookDetailView(book: book)) {
                EmptyView()
            }
            .opacity(0)
            
            // Visible book card
            BookCardView(book: book)
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 30)
        .animation(
            AppAnimation.spring.delay(animationDelay),
            value: hasAppeared
        )
        // Swipe LEFT to reveal Delete - applies only to this row
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
        .environmentObject(VocabViewModel())
}

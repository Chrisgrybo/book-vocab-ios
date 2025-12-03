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
    
    // MARK: - State
    
    @State private var showingAddBook: Bool = false
    @State private var searchText: String = ""
    @State private var hasAppeared: Bool = false
    
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
    
    private var totalBooks: Int { booksViewModel.books.count }
    private var totalWords: Int { vocabViewModel.totalWordCount }
    private var masteredWords: Int { vocabViewModel.masteredCount }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header with greeting and stats
                    headerSection
                    
                    // Main content
                    if booksViewModel.books.isEmpty {
                        emptyStateView
                            .padding(.top, AppSpacing.xxxl)
                    } else {
                        booksSection
                    }
                }
            }
            .background(AppColors.groupedBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    profileButton
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    addButton
                }
            }
            .searchable(text: $searchText, prompt: "Search books...")
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
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
    
    // MARK: - Books Section
    
    private var booksSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header
            HStack {
                Text("My Library")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(filteredBooks.count) books")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.top, AppSpacing.lg)
            
            // Book list
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookCardView(book: book)
                    }
                    .buttonStyle(.plain)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 30)
                    .animation(
                        AppAnimation.spring.delay(Double(index) * 0.05),
                        value: hasAppeared
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            Task {
                                await booksViewModel.deleteBook(book)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            .padding(.bottom, AppSpacing.xxxl)
        }
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
    
    private var profileButton: some View {
        Menu {
            Section {
                Label(session.currentUser?.email ?? "User", systemImage: "person.circle")
            }
            
            Section {
                Label("\(totalBooks) books", systemImage: "book.closed.fill")
                Label("\(totalWords) words learned", systemImage: "textformat.abc")
                Label("\(masteredWords) mastered", systemImage: "checkmark.circle.fill")
            }
            
            Divider()
            
            Button(role: .destructive) {
                Task {
                    await session.signOut()
                }
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
        } label: {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundStyle(AppColors.primary)
        }
    }
    
    private var addButton: some View {
        Button {
            showingAddBook = true
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

// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
        .environmentObject(VocabViewModel())
}

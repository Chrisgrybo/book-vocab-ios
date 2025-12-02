//
//  HomeView.swift
//  BookVocab
//
//  Main home screen displaying the user's book collection.
//  Shows book covers, word counts, and provides navigation to book details.
//

import SwiftUI

/// The home screen showing a list of the user's books.
///
/// Features:
/// - Book list with cover images and word counts
/// - Stats summary showing total books and words learned
/// - Search and filter functionality
/// - Pull to refresh
/// - Add book button
struct HomeView: View {
    
    // MARK: - Environment
    
    /// Access to the shared user session view model for sign out functionality.
    @EnvironmentObject var session: UserSessionViewModel
    
    /// Access to the shared books view model.
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// Controls presentation of the Add Book sheet.
    @State private var showingAddBook: Bool = false
    
    /// Search text for filtering books.
    @State private var searchText: String = ""
    
    // MARK: - Computed Properties
    
    /// Books filtered by search text.
    private var filteredBooks: [Book] {
        if searchText.isEmpty {
            return booksViewModel.books
        }
        return booksViewModel.books.filter { book in
            book.title.localizedCaseInsensitiveContains(searchText) ||
            book.author.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    /// Get the current user's email for display.
    private var userEmail: String {
        session.currentUser?.email ?? "User"
    }
    
    /// Total number of books in the collection.
    private var totalBooks: Int {
        booksViewModel.books.count
    }
    
    /// Total number of vocabulary words across all books.
    private var totalWords: Int {
        vocabViewModel.totalWordCount
    }
    
    /// Number of mastered words.
    private var masteredWords: Int {
        vocabViewModel.masteredCount
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if booksViewModel.books.isEmpty {
                    // Empty state when no books
                    emptyStateView
                } else {
                    // Main book list
                    bookListView
                }
            }
            .navigationTitle("My Books")
            .toolbar {
                // Add book button
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBook = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                
                // Profile/Settings menu
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        // User info section
                        Section {
                            Label(userEmail, systemImage: "person.circle")
                        }
                        
                        // Stats section
                        Section {
                            Label("\(totalBooks) books", systemImage: "book.closed")
                            Label("\(totalWords) words learned", systemImage: "textformat.abc")
                            Label("\(masteredWords) mastered", systemImage: "checkmark.circle")
                        }
                        
                        Divider()
                        
                        // Sign out
                        Button(role: .destructive) {
                            Task {
                                await session.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .refreshable {
                await booksViewModel.fetchBooks()
                await vocabViewModel.fetchAllWords()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state when user has no books.
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            // Illustration
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Welcome text
            VStack(spacing: 8) {
                Text("Welcome to Book Vocab!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Start building your vocabulary by adding books you're reading.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Add book button
            Button {
                showingAddBook = true
            } label: {
                Label("Add Your First Book", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
        }
        .padding()
    }
    
    /// Main list showing books with stats header.
    private var bookListView: some View {
        List {
            // Stats summary section
            Section {
                statsCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Books section
            Section {
                ForEach(filteredBooks) { book in
                    NavigationLink(destination: BookDetailView(book: book)) {
                        BookCard(book: book)
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .onDelete { offsets in
                    Task {
                        // Convert filtered offsets to actual book indices
                        let booksToDelete = offsets.map { filteredBooks[$0] }
                        for book in booksToDelete {
                            await booksViewModel.deleteBook(book)
                        }
                    }
                }
            } header: {
                if !searchText.isEmpty {
                    Text("Results for \"\(searchText)\"")
                } else {
                    Text("\(filteredBooks.count) \(filteredBooks.count == 1 ? "Book" : "Books")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, prompt: "Search books...")
    }
    
    /// Stats card showing vocabulary progress.
    private var statsCard: some View {
        HStack(spacing: 0) {
            // Total Words
            StatItem(
                value: "\(totalWords)",
                label: "Words",
                icon: "textformat.abc",
                color: .blue
            )
            
            Divider()
                .frame(height: 50)
            
            // Mastered
            StatItem(
                value: "\(masteredWords)",
                label: "Mastered",
                icon: "checkmark.circle.fill",
                color: .green
            )
            
            Divider()
                .frame(height: 50)
            
            // Learning
            StatItem(
                value: "\(totalWords - masteredWords)",
                label: "Learning",
                icon: "book.fill",
                color: .orange
            )
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

// MARK: - Stat Item

/// A single statistic display item.
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Book Card

/// A card displaying a single book with cover, title, author, and word count.
struct BookCard: View {
    
    /// The book to display.
    let book: Book
    
    /// Access to vocab view model to show word count.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Words for this book.
    private var bookWords: [VocabWord] {
        vocabViewModel.fetchWords(forBook: book.id)
    }
    
    /// Count of vocab words for this book.
    private var wordCount: Int {
        bookWords.count
    }
    
    /// Count of mastered words for this book.
    private var masteredCount: Int {
        bookWords.filter { $0.mastered }.count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover
            bookCoverView
            
            // Book info
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                // Author
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                // Word count badge
                HStack(spacing: 12) {
                    Label("\(wordCount) words", systemImage: "textformat.abc")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    
                    if masteredCount > 0 {
                        Label("\(masteredCount) mastered", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
            
            // Chevron indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
    
    /// Book cover image or placeholder.
    private var bookCoverView: some View {
        Group {
            if let coverUrl = book.coverImageUrl, !coverUrl.isEmpty {
                // Load cover image from URL
                AsyncImage(url: URL(string: coverUrl)) { phase in
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
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                    @unknown default:
                        coverPlaceholder
                    }
                }
            } else {
                coverPlaceholder
            }
        }
        .frame(width: 60, height: 85)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    /// Placeholder for books without cover images.
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                VStack(spacing: 4) {
                    Image(systemName: "book.closed.fill")
                        .font(.title3)
                        .foregroundStyle(.blue.opacity(0.6))
                    
                    Text(book.title.prefix(10))
                        .font(.system(size: 8))
                        .foregroundStyle(.blue.opacity(0.4))
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

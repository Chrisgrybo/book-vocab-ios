//
//  HomeView.swift
//  BookVocab
//
//  Main home screen displaying the user's book collection.
//  Provides navigation to book details and adding new books.
//
//  This is currently a placeholder that shows authentication was successful.
//  The full implementation will include the book list, add book functionality, etc.
//

import SwiftUI

/// The home screen showing a list of the user's books.
///
/// Currently serves as a placeholder to confirm successful authentication.
/// Will be expanded to show the book collection with full CRUD functionality.
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
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if booksViewModel.books.isEmpty {
                    // Placeholder content showing successful login
                    loggedInPlaceholder
                } else {
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
                        Image(systemName: "plus")
                    }
                }
                
                // Settings/Profile menu with sign out
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        // Show current user's email
                        Text(userEmail)
                        
                        Divider()
                        
                        // Sign out button
                        Button(role: .destructive) {
                            Task {
                                await session.signOut()
                            }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddBook) {
                AddBookView()
            }
            .refreshable {
                await booksViewModel.fetchBooks()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Placeholder view showing successful authentication.
    /// This confirms the user is logged in before the full UI is implemented.
    private var loggedInPlaceholder: some View {
        ContentUnavailableView {
            Label("Logged In!", systemImage: "checkmark.circle.fill")
        } description: {
            VStack(spacing: 12) {
                Text("Welcome to Book Vocab!")
                    .font(.headline)
                
                Text("Signed in as: \(userEmail)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Add your first book to start building your vocabulary.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        } actions: {
            Button {
                showingAddBook = true
            } label: {
                Text("Add Book")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    /// List of user's books.
    private var bookListView: some View {
        List {
            ForEach(filteredBooks) { book in
                NavigationLink(destination: BookDetailView(book: book)) {
                    BookRowView(book: book)
                }
            }
            .onDelete { offsets in
                Task {
                    await booksViewModel.deleteBooks(at: offsets)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, prompt: "Search books...")
    }
}

// MARK: - Book Row View

/// A single row in the book list.
struct BookRowView: View {
    
    /// The book to display.
    let book: Book
    
    /// Access to vocab view model to show word count.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Count of vocab words for this book.
    private var wordCount: Int {
        vocabViewModel.fetchWords(forBook: book.id).count
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Book cover placeholder
            bookCoverView
            
            // Book info
            VStack(alignment: .leading, spacing: 4) {
                Text(book.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(book.author)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("\(wordCount) words")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    /// Book cover image or placeholder.
    private var bookCoverView: some View {
        Group {
            if let coverUrl = book.coverImageUrl, !coverUrl.isEmpty {
                // Load cover image from URL
                AsyncImage(url: URL(string: coverUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    coverPlaceholder
                }
            } else {
                coverPlaceholder
            }
        }
        .frame(width: 50, height: 70)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
    
    /// Placeholder for books without cover images.
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue.opacity(0.2))
            .overlay {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.blue.opacity(0.5))
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

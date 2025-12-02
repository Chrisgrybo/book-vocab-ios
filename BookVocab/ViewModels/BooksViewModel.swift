//
//  BooksViewModel.swift
//  BookVocab
//
//  ViewModel for managing the user's book collection.
//  Handles fetching, adding, and deleting books via Supabase.
//

import Foundation
import SwiftUI

/// ViewModel responsible for managing the user's book collection.
/// Published as an environment object to share book data across views.
@MainActor
class BooksViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of books in the user's collection.
    @Published var books: [Book] = []
    
    /// The currently selected book for detail view.
    @Published var selectedBook: Book?
    
    /// Loading state for async operations.
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user.
    @Published var errorMessage: String?
    
    /// Search query for filtering books or searching new ones.
    @Published var searchQuery: String = ""
    
    // MARK: - Dependencies
    
    /// Reference to the Supabase service for database operations.
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    
    /// Creates a new BooksViewModel with optional dependency injection.
    /// - Parameter supabaseService: The Supabase service instance (defaults to shared)
    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
        
        // Load sample data for scaffolding
        #if DEBUG
        self.books = Book.samples
        #endif
    }
    
    // MARK: - Book Management Methods
    
    /// Fetches all books for the current user from Supabase.
    func fetchBooks() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase fetch
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            // Placeholder: Keep existing sample data
            // books = try await supabaseService.fetchBooks()
        } catch {
            errorMessage = "Failed to fetch books: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Adds a new book to the user's collection.
    /// - Parameter book: The book to add
    func addBook(_ book: Book) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase insert
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
            
            // Placeholder: Add to local array
            books.append(book)
        } catch {
            errorMessage = "Failed to add book: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Creates and adds a new book with the given details.
    /// - Parameters:
    ///   - title: Book title
    ///   - author: Book author
    ///   - coverImageUrl: Optional cover image URL
    ///   - userId: The user's ID
    func addBook(title: String, author: String, coverImageUrl: String? = nil, userId: UUID) async {
        let newBook = Book(
            userId: userId,
            title: title,
            author: author,
            coverImageUrl: coverImageUrl
        )
        await addBook(newBook)
    }
    
    /// Deletes a book from the user's collection.
    /// - Parameter book: The book to delete
    func deleteBook(_ book: Book) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase delete
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
            
            // Placeholder: Remove from local array
            books.removeAll { $0.id == book.id }
        } catch {
            errorMessage = "Failed to delete book: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Deletes books at the specified offsets (for SwiftUI list deletion).
    /// - Parameter offsets: The index set of books to delete
    func deleteBooks(at offsets: IndexSet) async {
        for index in offsets {
            let book = books[index]
            await deleteBook(book)
        }
    }
    
    /// Searches for books by title (for adding new books).
    /// - Parameter query: The search query
    /// - Returns: Array of matching books from external API
    func searchBooks(query: String) async -> [Book] {
        // TODO: Implement book search API (Google Books, Open Library, etc.)
        // For now, return empty array
        return []
    }
    
    /// Clears any displayed error message.
    func clearError() {
        errorMessage = nil
    }
}


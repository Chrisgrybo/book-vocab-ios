//
//  BooksViewModel.swift
//  BookVocab
//
//  ViewModel for managing the user's book collection.
//  Handles fetching, adding, and deleting books via Supabase with offline caching.
//
//  Features:
//  - Offline-first: loads from cache immediately, then syncs with Supabase
//  - Automatic caching of all book data
//  - Network-aware operations
//

import Foundation
import SwiftUI
import Combine
import os.log

/// Logger for BooksViewModel
private let logger = Logger(subsystem: "com.bookvocab.app", category: "BooksViewModel")

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
    
    /// Whether the app is currently offline.
    @Published var isOffline: Bool = false
    
    // MARK: - Dependencies
    
    /// Reference to the Supabase service for database operations.
    private let supabaseService: SupabaseService
    
    /// Reference to the cache service for offline storage.
    private let cacheService: CacheService
    
    /// Reference to the network monitor.
    private let networkMonitor: NetworkMonitor
    
    /// Cancellables for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// The current user's ID.
    private var currentUserId: UUID?
    
    // MARK: - Initialization
    
    /// Creates a new BooksViewModel with optional dependency injection.
    /// - Parameters:
    ///   - supabaseService: The Supabase service instance (defaults to shared)
    ///   - cacheService: The cache service instance (defaults to shared)
    ///   - networkMonitor: The network monitor instance (defaults to shared)
    init(
        supabaseService: SupabaseService = .shared,
        cacheService: CacheService = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.supabaseService = supabaseService
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
        
        setupNetworkObserver()
        
        // Load sample data for scaffolding in DEBUG
        #if DEBUG
        if books.isEmpty {
            self.books = Book.samples
        }
        #endif
        
        logger.info("📚 BooksViewModel initialized")
    }
    
    // MARK: - Network Observer
    
    /// Sets up observer for network status changes.
    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    logger.debug("📚 Network connected - can sync books")
                } else {
                    logger.debug("📚 Network disconnected - using cached books")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Book Management Methods
    
    /// Sets the current user ID for fetching books.
    /// - Parameter userId: The user's ID.
    func setUserId(_ userId: UUID) {
        self.currentUserId = userId
        logger.debug("📚 User ID set: \(userId.uuidString)")
    }
    
    /// Fetches all books for the current user.
    /// Loads from cache first, then fetches from Supabase if online.
    func fetchBooks() async {
        guard let userId = currentUserId else {
            logger.warning("📚 Cannot fetch books - no user ID set")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Step 1: Load from cache immediately (offline-first)
        let cachedBooks = cacheService.fetchBooks(for: userId)
        if !cachedBooks.isEmpty {
            books = cachedBooks
            logger.info("📚 Loaded \(cachedBooks.count) books from cache")
        }
        
        // Step 2: If online, fetch from Supabase and update cache
        if networkMonitor.isConnected {
            logger.debug("📚 Fetching books from Supabase...")
            
            // TODO: Replace with actual Supabase fetch
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
                
                // Placeholder: In real implementation:
                // let remoteBooks = try await supabaseService.fetchBooks(for: userId)
                // books = remoteBooks
                // cacheService.saveBooks(remoteBooks, needsSync: false)
                
                logger.info("📚 Books synced from Supabase")
            } catch {
                errorMessage = "Failed to fetch books: \(error.localizedDescription)"
                logger.error("📚 Failed to fetch from Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📚 Offline - using cached books only")
        }
        
        isLoading = false
    }
    
    /// Adds a new book to the user's collection.
    /// Saves to cache immediately and queues sync to Supabase.
    /// - Parameter book: The book to add
    func addBook(_ book: Book) async {
        isLoading = true
        errorMessage = nil
        
        logger.info("📚 Adding book: '\(book.title)'")
        
        // Add to local array immediately
        books.append(book)
        
        // Save to cache (will queue for sync if offline)
        cacheService.saveBook(book, needsSync: true)
        
        // If online, also sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase insert
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
                // await supabaseService.insertBook(book)
                logger.info("📚 Book synced to Supabase")
            } catch {
                errorMessage = "Failed to sync book: \(error.localizedDescription)"
                logger.error("📚 Failed to sync to Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📚 Offline - book saved to cache, will sync later")
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
    /// Removes from cache and queues delete for Supabase sync.
    /// - Parameter book: The book to delete
    func deleteBook(_ book: Book) async {
        isLoading = true
        errorMessage = nil
        
        logger.info("📚 Deleting book: '\(book.title)'")
        
        // Remove from local array immediately
        books.removeAll { $0.id == book.id }
        
        // Mark as deleted in cache (will queue for sync)
        cacheService.deleteBook(book.id, hardDelete: false)
        
        // If online, also sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase delete
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
                // await supabaseService.deleteBook(book.id)
                logger.info("📚 Book deletion synced to Supabase")
            } catch {
                errorMessage = "Failed to sync deletion: \(error.localizedDescription)"
                logger.error("📚 Failed to sync delete to Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📚 Offline - deletion saved to cache, will sync later")
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
    
    /// Forces a refresh from the server.
    func forceRefresh() async {
        logger.info("📚 Force refresh triggered")
        await fetchBooks()
    }
}

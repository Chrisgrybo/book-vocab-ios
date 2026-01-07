//
//  VocabViewModel.swift
//  BookVocab
//
//  ViewModel for managing vocabulary words.
//  Handles fetching, adding, and updating vocab words via Supabase with offline caching.
//
//  Features:
//  - Offline-first: loads from cache immediately, then syncs with Supabase
//  - Automatic caching of all vocab word data
//  - Network-aware operations
//  - Debug logging for mastered status updates
//

import Foundation
import SwiftUI
import Combine
import os.log

/// Logger for VocabViewModel debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "VocabViewModel")

/// ViewModel responsible for managing vocabulary words.
/// Published as an environment object to share vocab data across views.
@MainActor
class VocabViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of all vocabulary words across all books.
    @Published var allWords: [VocabWord] = []
    
    /// Loading state for async operations.
    @Published var isLoading: Bool = false
    
    /// Error message to display to the user.
    @Published var errorMessage: String?
    
    /// Search query for filtering words.
    @Published var searchQuery: String = ""
    
    /// Whether the app is currently offline.
    @Published var isOffline: Bool = false
    
    // MARK: - Computed Properties
    
    /// Returns words filtered by the current search query.
    var filteredWords: [VocabWord] {
        if searchQuery.isEmpty {
            return allWords
        }
        return allWords.filter { word in
            word.word.localizedCaseInsensitiveContains(searchQuery) ||
            word.definition.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    /// Returns only mastered words.
    var masteredWords: [VocabWord] {
        allWords.filter { $0.mastered }
    }
    
    /// Returns only words still being learned.
    var learningWords: [VocabWord] {
        allWords.filter { !$0.mastered }
    }
    
    /// Total count of all vocabulary words.
    var totalWordCount: Int {
        allWords.count
    }
    
    /// Count of mastered words.
    var masteredCount: Int {
        masteredWords.count
    }
    
    // MARK: - Dependencies
    
    /// Reference to the Supabase service for database operations.
    private let supabaseService: SupabaseService
    
    /// Reference to the Dictionary service for fetching definitions.
    private let dictionaryService: DictionaryService
    
    /// Reference to the cache service for offline storage.
    private let cacheService: CacheService
    
    /// Reference to the network monitor.
    private let networkMonitor: NetworkMonitor
    
    /// Cancellables for Combine subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    /// Creates a new VocabViewModel with optional dependency injection.
    /// - Parameters:
    ///   - supabaseService: The Supabase service instance (defaults to shared)
    ///   - dictionaryService: The Dictionary service instance (defaults to shared)
    ///   - cacheService: The cache service instance (defaults to shared)
    ///   - networkMonitor: The network monitor instance (defaults to shared)
    init(
        supabaseService: SupabaseService = .shared,
        dictionaryService: DictionaryService = .shared,
        cacheService: CacheService = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.supabaseService = supabaseService
        self.dictionaryService = dictionaryService
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
        
        setupNetworkObserver()
        
        // Load sample data for scaffolding in DEBUG
        #if DEBUG
        if allWords.isEmpty {
            self.allWords = VocabWord.samples
        }
        #endif
        
        logger.info("📝 VocabViewModel initialized")
    }
    
    // MARK: - Network Observer
    
    /// Sets up observer for network status changes.
    private func setupNetworkObserver() {
        networkMonitor.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOffline = !isConnected
                if isConnected {
                    logger.debug("📝 Network connected - can sync vocab words")
                } else {
                    logger.debug("📝 Network disconnected - using cached vocab words")
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Vocab Management Methods
    
    /// Fetches all vocabulary words for the current user.
    /// Loads from cache first, then fetches from Supabase if online.
    func fetchAllWords() async {
        isLoading = true
        errorMessage = nil
        
        // Step 1: Load from cache immediately (offline-first)
        let cachedWords = cacheService.fetchAllVocabWords()
        if !cachedWords.isEmpty {
            allWords = cachedWords
            logger.info("📝 Loaded \(cachedWords.count) vocab words from cache")
        }
        
        // Step 2: If online, fetch from Supabase and update cache
        if networkMonitor.isConnected {
            logger.debug("📝 Fetching vocab words from Supabase...")
            
            // TODO: Replace with actual Supabase fetch
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
                
                // Placeholder: In real implementation:
                // let remoteWords = try await supabaseService.fetchAllVocabWords()
                // allWords = remoteWords
                // cacheService.saveVocabWords(remoteWords, needsSync: false)
                
                logger.info("📝 Vocab words synced from Supabase")
            } catch {
                errorMessage = "Failed to fetch vocab words: \(error.localizedDescription)"
                logger.error("📝 Failed to fetch from Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📝 Offline - using cached vocab words only")
        }
        
        isLoading = false
    }
    
    /// Fetches vocabulary words for a specific book.
    /// - Parameter bookId: The book's unique identifier
    /// - Returns: Array of vocab words for that book
    func fetchWords(forBook bookId: UUID) -> [VocabWord] {
        // First check in-memory array
        let memoryWords = allWords.filter { $0.bookId == bookId }
        if !memoryWords.isEmpty {
            return memoryWords
        }
        
        // Fall back to cache
        return cacheService.fetchVocabWords(for: bookId)
    }
    
    /// Adds a new vocabulary word.
    /// Saves to cache immediately and queues sync to Supabase.
    /// - Parameter word: The vocab word to add
    func addWord(_ word: VocabWord) async {
        isLoading = true
        errorMessage = nil
        
        logger.info("📝 Adding vocab word: '\(word.word)'")
        
        // Add to local array immediately
        allWords.append(word)
        
        // Save to cache (will queue for sync if offline)
        cacheService.saveVocabWord(word, needsSync: true)
        
        // If online, also sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase insert
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
                // await supabaseService.insertVocabWord(word)
                logger.info("📝 Vocab word synced to Supabase")
            } catch {
                errorMessage = "Failed to sync vocab word: \(error.localizedDescription)"
                logger.error("📝 Failed to sync to Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📝 Offline - vocab word saved to cache, will sync later")
        }
        
        // Track word added event
        // Find book title if word is assigned to a book
        let bookTitle: String? = nil // Would need to look up from BooksViewModel
        AnalyticsService.shared.trackWordAdded(
            word: word.word,
            bookTitle: bookTitle,
            isGlobal: word.bookId == nil
        )
        
        isLoading = false
    }
    
    /// Looks up a word in the dictionary and creates a VocabWord.
    /// - Parameters:
    ///   - word: The word to look up
    ///   - bookId: The associated book's ID
    /// - Returns: A VocabWord with fetched definition, synonyms, etc.
    func lookupWord(_ word: String, forBook bookId: UUID) async -> VocabWord? {
        isLoading = true
        errorMessage = nil
        
        // Dictionary lookup requires network
        if !networkMonitor.isConnected {
            errorMessage = "Dictionary lookup requires internet connection"
            isLoading = false
            return nil
        }
        
        do {
            let wordDefinition = try await dictionaryService.fetchWord(word)
            
            let vocabWord = VocabWord(
                bookId: bookId,
                word: wordDefinition.word,
                definition: dictionaryService.getPrimaryDefinition(from: wordDefinition) ?? "No definition available",
                synonyms: dictionaryService.extractSynonyms(from: wordDefinition),
                antonyms: dictionaryService.extractAntonyms(from: wordDefinition),
                exampleSentence: dictionaryService.getFirstExample(from: wordDefinition) ?? ""
            )
            
            isLoading = false
            return vocabWord
        } catch {
            errorMessage = "Failed to look up word: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    /// Toggles the mastered status of a vocabulary word.
    /// Updates cache immediately and queues sync to Supabase.
    /// - Parameter word: The word to update
    func toggleMastered(_ word: VocabWord) async {
        guard let index = allWords.firstIndex(where: { $0.id == word.id }) else {
            logger.warning("📝 toggleMastered: Word '\(word.word)' not found in allWords")
            return
        }
        
        let newStatus = !allWords[index].mastered
        logger.info("📝 Toggling mastered status for '\(word.word)' to \(newStatus)")
        
        // Update local array
        allWords[index].mastered = newStatus
        
        // Update cache (will queue for sync)
        cacheService.updateMasteredStatus(word.id, mastered: newStatus)
        
        // If online, sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase update
            logger.debug("📝 Syncing mastered status to Supabase")
        } else {
            logger.debug("📝 Offline - mastered status saved to cache, will sync later")
        }
        
        logger.debug("📝 Updated '\(word.word)' mastered status to \(newStatus)")
    }
    
    /// Sets the mastered status of a vocabulary word to a specific value.
    /// NOTE: This function ONLY updates the mastered status. It does NOT delete the word.
    /// - Parameters:
    ///   - word: The word to update
    ///   - mastered: The new mastered status
    func setMastered(_ word: VocabWord, to mastered: Bool) async {
        guard let index = allWords.firstIndex(where: { $0.id == word.id }) else {
            logger.warning("📝 setMastered: Word '\(word.word)' (ID: \(word.id.uuidString.prefix(8))) not found in allWords array")
            logger.debug("📝 allWords contains \(self.allWords.count) words")
            return
        }
        
        let previousStatus = allWords[index].mastered
        logger.info("📝 Setting mastered status for '\(word.word)' from \(previousStatus) to \(mastered)")
        
        // Update local array (in-memory)
        allWords[index].mastered = mastered
        logger.debug("📝 Updated in-memory allWords[\(index)].mastered = \(mastered)")
        
        // Update cache (Core Data - will queue for Supabase sync)
        cacheService.updateMasteredStatus(word.id, mastered: mastered)
        logger.debug("📝 Updated cache for word ID: \(word.id.uuidString.prefix(8))")
        
        logger.info("✅ Successfully set '\(word.word)' mastered status to \(mastered)")
    }
    
    /// Updates an existing vocabulary word.
    /// Updates cache immediately and queues sync to Supabase.
    /// - Parameter word: The updated word data
    func updateWord(_ word: VocabWord) async throws {
        guard let index = allWords.firstIndex(where: { $0.id == word.id }) else {
            logger.warning("📝 updateWord: Word '\(word.word)' not found in allWords")
            throw VocabError.wordNotFound
        }
        
        logger.info("📝 Updating vocab word: '\(word.word)'")
        
        // Update local array immediately
        allWords[index] = word
        
        // Update cache (will queue for sync if offline)
        cacheService.updateVocabWord(word)
        
        // If online, also sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase update
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
                // await supabaseService.updateVocabWord(word)
                logger.info("📝 Vocab word update synced to Supabase")
            } catch {
                logger.error("📝 Failed to sync update to Supabase: \(error.localizedDescription)")
                throw error
            }
        } else {
            logger.debug("📝 Offline - word update saved to cache, will sync later")
        }
        
        // Track word edited event
        AnalyticsService.shared.track(.wordEdited, properties: [
            AnalyticsProperty.word.rawValue: word.word
        ])
        
        logger.info("✅ Successfully updated word: '\(word.word)'")
    }
    
    /// Deletes a vocabulary word.
    /// Removes from cache and queues delete for Supabase sync.
    /// - Parameter word: The word to delete
    func deleteWord(_ word: VocabWord) async {
        isLoading = true
        errorMessage = nil
        
        logger.info("📝 Deleting vocab word: '\(word.word)'")
        
        // Remove from local array immediately
        allWords.removeAll { $0.id == word.id }
        
        // Mark as deleted in cache (will queue for sync)
        cacheService.deleteVocabWord(word.id, hardDelete: false)
        
        // If online, also sync to Supabase
        if networkMonitor.isConnected {
            // TODO: Implement actual Supabase delete
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
                // await supabaseService.deleteVocabWord(word.id)
                logger.info("📝 Vocab word deletion synced to Supabase")
            } catch {
                errorMessage = "Failed to sync deletion: \(error.localizedDescription)"
                logger.error("📝 Failed to sync delete to Supabase: \(error.localizedDescription)")
            }
        } else {
            logger.debug("📝 Offline - deletion saved to cache, will sync later")
        }
        
        // Track word deleted event
        AnalyticsService.shared.track(.wordDeleted, properties: [
            AnalyticsProperty.word.rawValue: word.word
        ])
        
        isLoading = false
    }
    
    /// Deletes words at the specified offsets (for SwiftUI list deletion).
    /// - Parameter offsets: The index set of words to delete
    func deleteWords(at offsets: IndexSet) async {
        for index in offsets {
            let word = allWords[index]
            await deleteWord(word)
        }
    }
    
    /// Clears any displayed error message.
    func clearError() {
        errorMessage = nil
    }
    
    /// Forces a refresh from the server.
    func forceRefresh() async {
        logger.info("📝 Force refresh triggered")
        await fetchAllWords()
    }
    
    /// Deletes all words associated with a specific book.
    /// Called when a book is deleted.
    /// - Parameter bookId: The book's ID
    func deleteWords(forBook bookId: UUID) async {
        logger.info("📝 Deleting all words for book: \(bookId.uuidString.prefix(8))")
        
        let wordsToDelete = allWords.filter { $0.bookId == bookId }
        
        for word in wordsToDelete {
            await deleteWord(word)
        }
        
        logger.info("📝 Deleted \(wordsToDelete.count) words for book")
    }
}

// MARK: - Vocab Errors

/// Errors that can occur during vocabulary operations.
enum VocabError: LocalizedError {
    case wordNotFound
    case saveFailed(String)
    case deleteFailed(String)
    case networkRequired
    
    var errorDescription: String? {
        switch self {
        case .wordNotFound:
            return "Word not found in your vocabulary."
        case .saveFailed(let message):
            return "Failed to save word: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete word: \(message)"
        case .networkRequired:
            return "This action requires an internet connection."
        }
    }
}

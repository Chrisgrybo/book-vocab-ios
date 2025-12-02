//
//  VocabViewModel.swift
//  BookVocab
//
//  ViewModel for managing vocabulary words.
//  Handles fetching, adding, and updating vocab words via Supabase.
//

import Foundation
import SwiftUI

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
    
    // MARK: - Initialization
    
    /// Creates a new VocabViewModel with optional dependency injection.
    /// - Parameters:
    ///   - supabaseService: The Supabase service instance (defaults to shared)
    ///   - dictionaryService: The Dictionary service instance (defaults to shared)
    init(
        supabaseService: SupabaseService = .shared,
        dictionaryService: DictionaryService = .shared
    ) {
        self.supabaseService = supabaseService
        self.dictionaryService = dictionaryService
        
        // Load sample data for scaffolding
        #if DEBUG
        self.allWords = VocabWord.samples
        #endif
    }
    
    // MARK: - Vocab Management Methods
    
    /// Fetches all vocabulary words for the current user from Supabase.
    func fetchAllWords() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase fetch
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            // Placeholder: Keep existing sample data
            // allWords = try await supabaseService.fetchAllVocabWords()
        } catch {
            errorMessage = "Failed to fetch words: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Fetches vocabulary words for a specific book.
    /// - Parameter bookId: The book's unique identifier
    /// - Returns: Array of vocab words for that book
    func fetchWords(forBook bookId: UUID) -> [VocabWord] {
        return allWords.filter { $0.bookId == bookId }
    }
    
    /// Adds a new vocabulary word.
    /// - Parameter word: The vocab word to add
    func addWord(_ word: VocabWord) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase insert
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
            
            // Placeholder: Add to local array
            allWords.append(word)
        } catch {
            errorMessage = "Failed to add word: \(error.localizedDescription)"
        }
        
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
        
        // TODO: Implement actual dictionary API lookup
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            // Placeholder: Return a mock word
            let vocabWord = VocabWord(
                bookId: bookId,
                word: word,
                definition: "Definition placeholder - connect dictionary API",
                synonyms: [],
                antonyms: [],
                exampleSentence: ""
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
    /// - Parameter word: The word to update
    func toggleMastered(_ word: VocabWord) async {
        guard let index = allWords.firstIndex(where: { $0.id == word.id }) else { return }
        
        // TODO: Implement actual Supabase update
        allWords[index].mastered.toggle()
    }
    
    /// Deletes a vocabulary word.
    /// - Parameter word: The word to delete
    func deleteWord(_ word: VocabWord) async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual Supabase delete
        do {
            try await Task.sleep(nanoseconds: 300_000_000) // Simulate network delay
            
            // Placeholder: Remove from local array
            allWords.removeAll { $0.id == word.id }
        } catch {
            errorMessage = "Failed to delete word: \(error.localizedDescription)"
        }
        
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
}


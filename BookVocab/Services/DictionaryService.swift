//
//  DictionaryService.swift
//  BookVocab
//
//  Service layer for dictionary API integration.
//  Fetches word definitions, synonyms, antonyms, and example sentences.
//
//  TODO: Implement actual dictionary API (e.g., Free Dictionary API, Merriam-Webster).
//

import Foundation

/// Response model for dictionary API lookups.
struct DictionaryResponse: Codable {
    let word: String
    let definition: String
    let synonyms: [String]
    let antonyms: [String]
    let exampleSentence: String?
    let partOfSpeech: String?
}

/// Service class for dictionary API operations.
/// Implements singleton pattern for shared access across the app.
class DictionaryService {
    
    // MARK: - Singleton
    
    /// Shared instance of the Dictionary service.
    static let shared = DictionaryService()
    
    // MARK: - Configuration
    
    /// Base URL for the dictionary API - TODO: Replace with actual API
    private let baseUrl = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern.
    private init() {}
    
    // MARK: - API Methods
    
    /// Looks up a word in the dictionary.
    /// - Parameter word: The word to look up
    /// - Returns: DictionaryResponse with word details
    /// - Throws: Network or parsing error
    func lookupWord(_ word: String) async throws -> DictionaryResponse {
        // TODO: Implement actual API call
        // let url = URL(string: "\(baseUrl)\(word.lowercased())")!
        // let (data, _) = try await URLSession.shared.data(from: url)
        // let response = try JSONDecoder().decode([DictionaryAPIResponse].self, from: data)
        // return transform to DictionaryResponse
        
        // Placeholder: Return mock data
        return DictionaryResponse(
            word: word,
            definition: "Definition will be fetched from dictionary API",
            synonyms: ["synonym1", "synonym2"],
            antonyms: ["antonym1", "antonym2"],
            exampleSentence: "Example sentence will be fetched from dictionary API",
            partOfSpeech: "noun"
        )
    }
    
    /// Fetches synonyms for a word.
    /// - Parameter word: The word to find synonyms for
    /// - Returns: Array of synonym strings
    /// - Throws: Network or parsing error
    func fetchSynonyms(_ word: String) async throws -> [String] {
        // TODO: Implement API call for synonyms
        // May use same API as lookupWord or a dedicated thesaurus API
        
        // Placeholder: Return empty array
        return []
    }
    
    /// Fetches antonyms for a word.
    /// - Parameter word: The word to find antonyms for
    /// - Returns: Array of antonym strings
    /// - Throws: Network or parsing error
    func fetchAntonyms(_ word: String) async throws -> [String] {
        // TODO: Implement API call for antonyms
        // May use same API as lookupWord or a dedicated thesaurus API
        
        // Placeholder: Return empty array
        return []
    }
    
    /// Fetches example sentences for a word.
    /// - Parameter word: The word to find examples for
    /// - Returns: Array of example sentence strings
    /// - Throws: Network or parsing error
    func fetchExamples(_ word: String) async throws -> [String] {
        // TODO: Implement API call for examples
        
        // Placeholder: Return empty array
        return []
    }
    
    /// Creates a VocabWord from a dictionary lookup.
    /// - Parameters:
    ///   - word: The word to look up
    ///   - bookId: The associated book's ID
    /// - Returns: A fully populated VocabWord
    /// - Throws: Network or parsing error
    func createVocabWord(from word: String, bookId: UUID) async throws -> VocabWord {
        let response = try await lookupWord(word)
        
        return VocabWord(
            bookId: bookId,
            word: response.word,
            definition: response.definition,
            synonyms: response.synonyms,
            antonyms: response.antonyms,
            exampleSentence: response.exampleSentence ?? ""
        )
    }
}


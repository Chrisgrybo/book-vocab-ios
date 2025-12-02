//
//  DictionaryService.swift
//  BookVocab
//
//  Service layer for dictionary API integration.
//  Fetches word definitions, synonyms, antonyms, and example sentences
//  using the Free Dictionary API (https://dictionaryapi.dev).
//

import Foundation

// MARK: - API Response Models

/// Represents a complete word definition from the Free Dictionary API.
/// The API returns an array of these, so we typically use the first one.
struct WordDefinition: Codable {
    /// The word that was looked up.
    let word: String
    
    /// Array of meanings for different parts of speech.
    /// A word can have multiple meanings (e.g., "run" as noun vs verb).
    let meanings: [Meaning]
}

/// Represents a single meaning/usage of a word for a specific part of speech.
struct Meaning: Codable {
    /// The part of speech (e.g., "noun", "verb", "adjective").
    let partOfSpeech: String
    
    /// Array of definitions for this part of speech.
    let definitions: [Definition]
    
    /// Array of synonyms (words with similar meaning).
    /// Optional because not all words have synonyms listed.
    let synonyms: [String]?
    
    /// Array of antonyms (words with opposite meaning).
    /// Optional because not all words have antonyms listed.
    let antonyms: [String]?
}

/// Represents a single definition of a word.
struct Definition: Codable {
    /// The actual definition text.
    let definition: String
    
    /// An example sentence using the word.
    /// Optional because not all definitions include examples.
    let example: String?
}

// MARK: - Error Types

/// Custom errors for dictionary lookup operations.
enum DictionaryError: LocalizedError {
    /// The word was not found in the dictionary.
    case wordNotFound(String)
    
    /// A network error occurred during the API call.
    case networkError(Error)
    
    /// The API response could not be decoded.
    case decodingError(Error)
    
    /// The URL could not be constructed (invalid word).
    case invalidURL
    
    /// User-friendly error descriptions.
    var errorDescription: String? {
        switch self {
        case .wordNotFound(let word):
            return "The word '\(word)' was not found in the dictionary."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse dictionary response."
        case .invalidURL:
            return "Invalid word entered."
        }
    }
}

// MARK: - Dictionary Service

/// Service class for dictionary API operations.
/// Implements singleton pattern for shared access across the app.
///
/// Usage:
/// ```swift
/// let definition = try await DictionaryService.shared.fetchWord("ephemeral")
/// print(definition.meanings.first?.definitions.first?.definition)
/// ```
class DictionaryService {
    
    // MARK: - Singleton
    
    /// Shared instance of the Dictionary service.
    /// Use this throughout the app for dictionary lookups.
    static let shared = DictionaryService()
    
    // MARK: - Configuration
    
    /// Base URL for the Free Dictionary API.
    /// API documentation: https://dictionaryapi.dev
    private let baseUrl = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    
    /// URLSession configured for API requests.
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern.
    /// Configures URLSession with appropriate timeout settings.
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0  // 10 second timeout
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// Fetches the definition of a word from the Free Dictionary API.
    ///
    /// This method:
    /// 1. Constructs the API URL with the word (URL-encoded)
    /// 2. Makes an async network request
    /// 3. Decodes the JSON response into WordDefinition
    /// 4. Returns the first definition (APIs return an array)
    ///
    /// - Parameter word: The word to look up (will be lowercased and URL-encoded)
    /// - Returns: A WordDefinition containing all meanings, definitions, synonyms, etc.
    /// - Throws: DictionaryError if the lookup fails
    ///
    /// Example:
    /// ```swift
    /// do {
    ///     let result = try await DictionaryService.shared.fetchWord("serendipity")
    ///     print(result.meanings.first?.definitions.first?.definition ?? "")
    /// } catch {
    ///     print("Lookup failed: \(error.localizedDescription)")
    /// }
    /// ```
    func fetchWord(_ word: String) async throws -> WordDefinition {
        // Trim whitespace and convert to lowercase for consistent lookups
        let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // URL-encode the word to handle special characters
        guard let encodedWord = cleanedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(baseUrl)\(encodedWord)") else {
            throw DictionaryError.invalidURL
        }
        
        // Make the network request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw DictionaryError.networkError(error)
        }
        
        // Check for HTTP errors
        if let httpResponse = response as? HTTPURLResponse {
            // 404 means word not found
            if httpResponse.statusCode == 404 {
                throw DictionaryError.wordNotFound(word)
            }
            
            // Any non-2xx status is an error
            guard (200...299).contains(httpResponse.statusCode) else {
                throw DictionaryError.networkError(
                    NSError(domain: "HTTP", code: httpResponse.statusCode)
                )
            }
        }
        
        // Decode the JSON response
        // The API returns an array of WordDefinition, we use the first one
        do {
            let definitions = try JSONDecoder().decode([WordDefinition].self, from: data)
            
            // Return the first definition (there's usually just one)
            guard let firstDefinition = definitions.first else {
                throw DictionaryError.wordNotFound(word)
            }
            
            return firstDefinition
        } catch let error as DecodingError {
            throw DictionaryError.decodingError(error)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Extracts a flat list of all synonyms from a WordDefinition.
    ///
    /// - Parameter definition: The WordDefinition to extract synonyms from
    /// - Returns: Array of unique synonym strings
    func extractSynonyms(from definition: WordDefinition) -> [String] {
        var allSynonyms: [String] = []
        
        for meaning in definition.meanings {
            if let synonyms = meaning.synonyms {
                allSynonyms.append(contentsOf: synonyms)
            }
        }
        
        // Remove duplicates while preserving order
        return Array(NSOrderedSet(array: allSynonyms)) as? [String] ?? allSynonyms
    }
    
    /// Extracts a flat list of all antonyms from a WordDefinition.
    ///
    /// - Parameter definition: The WordDefinition to extract antonyms from
    /// - Returns: Array of unique antonym strings
    func extractAntonyms(from definition: WordDefinition) -> [String] {
        var allAntonyms: [String] = []
        
        for meaning in definition.meanings {
            if let antonyms = meaning.antonyms {
                allAntonyms.append(contentsOf: antonyms)
            }
        }
        
        // Remove duplicates while preserving order
        return Array(NSOrderedSet(array: allAntonyms)) as? [String] ?? allAntonyms
    }
    
    /// Gets the primary (first) definition text from a WordDefinition.
    ///
    /// - Parameter definition: The WordDefinition to extract from
    /// - Returns: The first definition string, or nil if none exists
    func getPrimaryDefinition(from definition: WordDefinition) -> String? {
        return definition.meanings.first?.definitions.first?.definition
    }
    
    /// Gets the first example sentence from a WordDefinition.
    ///
    /// - Parameter definition: The WordDefinition to extract from
    /// - Returns: The first example sentence, or nil if none exists
    func getFirstExample(from definition: WordDefinition) -> String? {
        for meaning in definition.meanings {
            for def in meaning.definitions {
                if let example = def.example, !example.isEmpty {
                    return example
                }
            }
        }
        return nil
    }
    
    /// Gets the primary part of speech from a WordDefinition.
    ///
    /// - Parameter definition: The WordDefinition to extract from
    /// - Returns: The first part of speech string, or nil if none exists
    func getPrimaryPartOfSpeech(from definition: WordDefinition) -> String? {
        return definition.meanings.first?.partOfSpeech
    }
}

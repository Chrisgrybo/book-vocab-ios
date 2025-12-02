//
//  VocabWord.swift
//  BookVocab
//
//  Data model representing a vocabulary word saved from a book.
//  Includes definition, synonyms, antonyms, and learning status.
//

import Foundation

/// Represents a vocabulary word that the user is learning.
/// Associated with a specific book and tracks mastery status.
struct VocabWord: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the vocabulary word.
    let id: UUID
    
    /// The ID of the book this word was found in.
    let bookId: UUID
    
    /// The vocabulary word itself.
    var word: String
    
    /// The definition of the word.
    var definition: String
    
    /// Array of synonyms for the word.
    var synonyms: [String]
    
    /// Array of antonyms for the word.
    var antonyms: [String]
    
    /// An example sentence using the word.
    var exampleSentence: String
    
    /// Whether the user has mastered this word.
    var mastered: Bool
    
    /// Timestamp when the word was added.
    let createdAt: Date
    
    // MARK: - Coding Keys
    
    /// Maps property names to JSON keys for Supabase compatibility.
    enum CodingKeys: String, CodingKey {
        case id
        case bookId = "book_id"
        case word
        case definition
        case synonyms
        case antonyms
        case exampleSentence = "example_sentence"
        case mastered
        case createdAt = "created_at"
    }
    
    // MARK: - Initialization
    
    /// Creates a new VocabWord instance with all required properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - bookId: The associated book's ID
    ///   - word: The vocabulary word
    ///   - definition: Word definition
    ///   - synonyms: Array of synonyms (defaults to empty)
    ///   - antonyms: Array of antonyms (defaults to empty)
    ///   - exampleSentence: Example usage (defaults to empty string)
    ///   - mastered: Learning status (defaults to false)
    ///   - createdAt: Creation timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        bookId: UUID,
        word: String,
        definition: String,
        synonyms: [String] = [],
        antonyms: [String] = [],
        exampleSentence: String = "",
        mastered: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.word = word
        self.definition = definition
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.exampleSentence = exampleSentence
        self.mastered = mastered
        self.createdAt = createdAt
    }
}

// MARK: - Preview Helpers

extension VocabWord {
    /// Sample vocab word for SwiftUI previews and testing.
    static let sample = VocabWord(
        bookId: UUID(),
        word: "Ephemeral",
        definition: "Lasting for a very short time",
        synonyms: ["Fleeting", "Transient", "Brief"],
        antonyms: ["Permanent", "Lasting", "Enduring"],
        exampleSentence: "The ephemeral beauty of the sunset lasted only moments."
    )
    
    /// Array of sample vocab words for list previews and study testing.
    /// Includes enough words for quiz mode (minimum 4 required).
    static let samples: [VocabWord] = [
        VocabWord(
            bookId: UUID(),
            word: "Ephemeral",
            definition: "Lasting for a very short time",
            synonyms: ["Fleeting", "Transient"],
            antonyms: ["Permanent", "Lasting"],
            exampleSentence: "The ephemeral beauty of the sunset lasted only moments."
        ),
        VocabWord(
            bookId: UUID(),
            word: "Ubiquitous",
            definition: "Present, appearing, or found everywhere",
            synonyms: ["Omnipresent", "Pervasive"],
            antonyms: ["Rare", "Scarce"],
            exampleSentence: "Smartphones have become ubiquitous in modern society."
        ),
        VocabWord(
            bookId: UUID(),
            word: "Serendipity",
            definition: "The occurrence of events by chance in a happy way",
            synonyms: ["Fortune", "Luck"],
            antonyms: ["Misfortune", "Design"],
            exampleSentence: "It was pure serendipity that they met at the bookstore.",
            mastered: true
        ),
        VocabWord(
            bookId: UUID(),
            word: "Eloquent",
            definition: "Fluent or persuasive in speaking or writing",
            synonyms: ["Articulate", "Expressive"],
            antonyms: ["Inarticulate", "Tongue-tied"],
            exampleSentence: "The lawyer gave an eloquent closing argument."
        ),
        VocabWord(
            bookId: UUID(),
            word: "Pragmatic",
            definition: "Dealing with things sensibly and realistically",
            synonyms: ["Practical", "Realistic"],
            antonyms: ["Idealistic", "Impractical"],
            exampleSentence: "She took a pragmatic approach to solving the problem."
        ),
        VocabWord(
            bookId: UUID(),
            word: "Benevolent",
            definition: "Well-meaning and kindly",
            synonyms: ["Kind", "Charitable"],
            antonyms: ["Malevolent", "Cruel"],
            exampleSentence: "The benevolent donor gave generously to the charity.",
            mastered: true
        ),
        VocabWord(
            bookId: UUID(),
            word: "Cacophony",
            definition: "A harsh, discordant mixture of sounds",
            synonyms: ["Noise", "Discord"],
            antonyms: ["Harmony", "Melody"],
            exampleSentence: "The cacophony of car horns filled the busy street."
        ),
        VocabWord(
            bookId: UUID(),
            word: "Diligent",
            definition: "Having or showing care in one's work or duties",
            synonyms: ["Hardworking", "Industrious"],
            antonyms: ["Lazy", "Negligent"],
            exampleSentence: "The diligent student always completed homework on time."
        )
    ]
}


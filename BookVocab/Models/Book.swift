//
//  Book.swift
//  BookVocab
//
//  Data model representing a book in the user's collection.
//  Stores metadata about books including title, author, and cover image.
//

import Foundation

/// Represents a book in the user's vocabulary collection.
/// Conforms to Identifiable for use in SwiftUI lists and Codable for JSON serialization.
struct Book: Identifiable, Codable, Hashable {
    
    // MARK: - Properties
    
    /// Unique identifier for the book (UUID from Supabase).
    let id: UUID
    
    /// The ID of the user who owns this book.
    let userId: UUID
    
    /// The title of the book.
    var title: String
    
    /// The author of the book.
    var author: String
    
    /// URL string for the book's cover image (optional).
    var coverImageUrl: String?
    
    /// Timestamp when the book was added to the collection.
    let createdAt: Date
    
    // MARK: - Coding Keys
    
    /// Maps property names to JSON keys for Supabase compatibility.
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case author
        case coverImageUrl = "cover_image_url"
        case createdAt = "created_at"
    }
    
    // MARK: - Initialization
    
    /// Creates a new Book instance with all required properties.
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - userId: The owning user's ID
    ///   - title: Book title
    ///   - author: Book author
    ///   - coverImageUrl: Optional URL for cover image
    ///   - createdAt: Creation timestamp (defaults to now)
    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String,
        author: String,
        coverImageUrl: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.author = author
        self.coverImageUrl = coverImageUrl
        self.createdAt = createdAt
    }
}

// MARK: - Preview Helpers

extension Book {
    /// Sample book for SwiftUI previews and testing.
    /// Includes a real Google Books cover URL for testing.
    static let sample = Book(
        userId: UUID(),
        title: "The Great Gatsby",
        author: "F. Scott Fitzgerald",
        coverImageUrl: "https://books.google.com/books/content?id=iXn5U2IzVH0C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
    )
    
    /// Array of sample books for list previews.
    /// Includes a mix of books with and without covers for testing placeholder display.
    static let samples: [Book] = [
        Book(
            userId: UUID(),
            title: "The Great Gatsby",
            author: "F. Scott Fitzgerald",
            coverImageUrl: "https://books.google.com/books/content?id=iXn5U2IzVH0C&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
        ),
        Book(
            userId: UUID(),
            title: "To Kill a Mockingbird",
            author: "Harper Lee",
            coverImageUrl: "https://books.google.com/books/content?id=PGR2AwAAQBAJ&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
        ),
        Book(
            userId: UUID(),
            title: "1984",
            author: "George Orwell",
            coverImageUrl: "https://books.google.com/books/content?id=kotPYEqx7kMC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api"
        ),
        Book(
            userId: UUID(),
            title: "Pride and Prejudice",
            author: "Jane Austen",
            coverImageUrl: nil // Test placeholder display
        )
    ]
}


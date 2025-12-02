//
//  User.swift
//  BookVocab
//
//  Data model representing an authenticated user.
//  Used for managing user session and profile data.
//

import Foundation

/// Represents an authenticated user in the application.
/// Stores basic user information from Supabase Auth.
struct User: Identifiable, Codable {
    
    // MARK: - Properties
    
    /// Unique identifier for the user (from Supabase Auth).
    let id: UUID
    
    /// User's email address.
    let email: String
    
    /// User's display name (optional).
    var displayName: String?
    
    /// Timestamp when the user account was created.
    let createdAt: Date
    
    // MARK: - Coding Keys
    
    /// Maps property names to JSON keys for Supabase compatibility.
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName = "display_name"
        case createdAt = "created_at"
    }
    
    // MARK: - Initialization
    
    /// Creates a new User instance.
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - email: User's email
    ///   - displayName: Optional display name
    ///   - createdAt: Account creation timestamp
    init(
        id: UUID = UUID(),
        email: String,
        displayName: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
}

// MARK: - Preview Helpers

extension User {
    /// Sample user for SwiftUI previews and testing.
    static let sample = User(
        email: "reader@bookvocab.com",
        displayName: "Book Lover"
    )
}


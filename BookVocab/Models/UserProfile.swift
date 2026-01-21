//
//  UserProfile.swift
//  BookVocab
//
//  Data model representing a user's profile.
//  Stores display name, avatar, and aggregated stats.
//

import Foundation

/// Represents a user's profile with display information and stats.
/// Syncs with the `user_profiles` table in Supabase.
struct UserProfile: Codable, Equatable {
    
    // MARK: - Properties
    
    /// The user's ID (primary key, matches auth.users)
    let userId: UUID
    
    /// User's display name
    var displayName: String?
    
    /// URL to user's avatar image
    var avatarUrl: String?
    
    /// Total number of books in user's collection
    var totalBooks: Int
    
    /// Total number of vocabulary words
    var totalWords: Int
    
    /// Number of words marked as mastered
    var masteredWords: Int
    
    /// Total number of completed study sessions
    var totalStudySessions: Int
    
    /// Timestamp when the profile was created
    let createdAt: Date
    
    /// Timestamp when the profile was last updated
    var updatedAt: Date
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case totalBooks = "total_books"
        case totalWords = "total_words"
        case masteredWords = "mastered_words"
        case totalStudySessions = "total_study_sessions"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    
    /// Creates a new UserProfile with default values.
    /// - Parameter userId: The user's UUID from Supabase auth
    init(
        userId: UUID,
        displayName: String? = nil,
        avatarUrl: String? = nil,
        totalBooks: Int = 0,
        totalWords: Int = 0,
        masteredWords: Int = 0,
        totalStudySessions: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.displayName = displayName
        self.avatarUrl = avatarUrl
        self.totalBooks = totalBooks
        self.totalWords = totalWords
        self.masteredWords = masteredWords
        self.totalStudySessions = totalStudySessions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    
    /// Progress percentage of mastered words (0.0 to 1.0)
    var masteryProgress: Double {
        guard totalWords > 0 else { return 0 }
        return Double(masteredWords) / Double(totalWords)
    }
    
    /// Formatted display name or fallback
    var displayNameOrDefault: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return "Reader"
    }
}

// MARK: - Insert Model (for creating new profiles)

/// Model for inserting a new user profile into Supabase.
/// Excludes server-generated fields like timestamps.
struct UserProfileInsert: Codable {
    let userId: UUID
    var displayName: String?
    var avatarUrl: String?
    var totalBooks: Int
    var totalWords: Int
    var masteredWords: Int
    var totalStudySessions: Int
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case totalBooks = "total_books"
        case totalWords = "total_words"
        case masteredWords = "mastered_words"
        case totalStudySessions = "total_study_sessions"
    }
    
    /// Creates an insert model with default values for a new user.
    init(userId: UUID, displayName: String? = nil) {
        self.userId = userId
        self.displayName = displayName
        self.avatarUrl = nil
        self.totalBooks = 0
        self.totalWords = 0
        self.masteredWords = 0
        self.totalStudySessions = 0
    }
}

//
//  SupabaseService.swift
//  BookVocab
//
//  Service layer for Supabase backend integration.
//  Handles authentication, database operations, and real-time subscriptions.
//
//  This singleton provides a centralized Supabase client that can be accessed
//  throughout the app via SupabaseService.shared.client
//

import Foundation
import Auth
import PostgREST
import Supabase
import os.log

/// Logger for Supabase operations
private let logger = Logger(subsystem: "com.bookvocab.app", category: "SupabaseService")

/// Service class for all Supabase backend operations.
/// Implements singleton pattern for shared access across the app.
///
/// Usage:
/// ```swift
/// let client = SupabaseService.shared.client
/// let session = try await client.auth.signIn(email: email, password: password)
/// ```
class SupabaseService {
    
    // MARK: - Singleton
    
    /// Shared instance of the Supabase service.
    /// Use this to access the Supabase client throughout the app.
    static let shared = SupabaseService()
    
    // MARK: - Properties
    
    /// The Supabase client instance.
    /// This is the main entry point for all Supabase operations including:
    /// - Authentication (client.auth)
    /// - Database queries (client.from("table"))
    /// - Storage (client.storage)
    /// - Realtime subscriptions (client.realtime)
    let client: SupabaseClient
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern.
    /// Creates and configures the Supabase client using credentials from Secrets.swift
    private init() {
        // Initialize the Supabase client with project credentials from Secrets
        // The client handles token storage, refresh, and all API communications
        //
        // Note: The Supabase SDK may show a warning about emitLocalSessionAsInitialSession.
        // This is informational about future API changes and can be safely ignored for now.
        self.client = SupabaseClient(
            supabaseURL: URL(string: Secrets.supabaseUrl)!,
            supabaseKey: Secrets.supabaseKey
        )
    }
    
    // MARK: - Books CRUD Operations
    
    /// Fetches all books for a specific user from Supabase.
    /// - Parameter userId: The user's UUID
    /// - Returns: Array of Book objects
    func fetchBooks(for userId: UUID) async throws -> [Book] {
        logger.info("📚 Fetching books for user: \(userId.uuidString.prefix(8))")
        
        let books: [Book] = try await client
            .from("books")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        logger.info("📚 Fetched \(books.count) books from Supabase")
        return books
    }
    
    /// Inserts a new book into Supabase.
    /// - Parameter book: The book to insert
    func insertBook(_ book: Book) async throws {
        logger.info("📚 Inserting book: '\(book.title)'")
        
        try await client
            .from("books")
            .insert(book)
            .execute()
        
        logger.info("📚 Book inserted successfully")
    }
    
    /// Updates an existing book in Supabase.
    /// - Parameter book: The book with updated values
    func updateBook(_ book: Book) async throws {
        logger.info("📚 Updating book: '\(book.title)'")
        
        try await client
            .from("books")
            .update(book)
            .eq("id", value: book.id.uuidString)
            .execute()
        
        logger.info("📚 Book updated successfully")
    }
    
    /// Deletes a book from Supabase.
    /// Associated vocab words will be cascade deleted by the database.
    /// - Parameter bookId: The book's UUID
    func deleteBook(_ bookId: UUID) async throws {
        logger.info("📚 Deleting book: \(bookId.uuidString.prefix(8))")
        
        try await client
            .from("books")
            .delete()
            .eq("id", value: bookId.uuidString)
            .execute()
        
        logger.info("📚 Book deleted successfully")
    }
    
    // MARK: - Vocab Words CRUD Operations
    
    /// Fetches all vocab words for a specific user from Supabase.
    /// - Parameter userId: The user's UUID
    /// - Returns: Array of VocabWord objects
    func fetchAllVocabWords(for userId: UUID) async throws -> [VocabWord] {
        logger.info("📝 Fetching all vocab words for user: \(userId.uuidString.prefix(8))")
        
        let words: [VocabWord] = try await client
            .from("vocab_words")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        logger.info("📝 Fetched \(words.count) vocab words from Supabase")
        return words
    }
    
    /// Fetches vocab words for a specific book from Supabase.
    /// - Parameter bookId: The book's UUID
    /// - Returns: Array of VocabWord objects
    func fetchVocabWords(for bookId: UUID) async throws -> [VocabWord] {
        logger.info("📝 Fetching vocab words for book: \(bookId.uuidString.prefix(8))")
        
        let words: [VocabWord] = try await client
            .from("vocab_words")
            .select()
            .eq("book_id", value: bookId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        logger.info("📝 Fetched \(words.count) vocab words for book")
        return words
    }
    
    /// Inserts a new vocab word into Supabase.
    /// - Parameter word: The vocab word to insert
    func insertVocabWord(_ word: VocabWord) async throws {
        logger.info("📝 Inserting vocab word: '\(word.word)'")
        
        try await client
            .from("vocab_words")
            .insert(word)
            .execute()
        
        logger.info("📝 Vocab word inserted successfully")
    }
    
    /// Updates an existing vocab word in Supabase.
    /// - Parameter word: The vocab word with updated values
    func updateVocabWord(_ word: VocabWord) async throws {
        logger.info("📝 Updating vocab word: '\(word.word)'")
        
        try await client
            .from("vocab_words")
            .update(word)
            .eq("id", value: word.id.uuidString)
            .execute()
        
        logger.info("📝 Vocab word updated successfully")
    }
    
    /// Updates only the mastered status of a vocab word.
    /// - Parameters:
    ///   - wordId: The word's UUID
    ///   - mastered: The new mastered status
    func updateMasteredStatus(_ wordId: UUID, mastered: Bool) async throws {
        logger.info("📝 Updating mastered status for word: \(wordId.uuidString.prefix(8)) to \(mastered)")
        
        try await client
            .from("vocab_words")
            .update(["mastered": mastered])
            .eq("id", value: wordId.uuidString)
            .execute()
        
        logger.info("📝 Mastered status updated successfully")
    }
    
    /// Deletes a vocab word from Supabase.
    /// - Parameter wordId: The word's UUID
    func deleteVocabWord(_ wordId: UUID) async throws {
        logger.info("📝 Deleting vocab word: \(wordId.uuidString.prefix(8))")
        
        try await client
            .from("vocab_words")
            .delete()
            .eq("id", value: wordId.uuidString)
            .execute()
        
        logger.info("📝 Vocab word deleted successfully")
    }
    
    // MARK: - Study Sessions
    
    /// Model for inserting study sessions (matches database schema)
    struct StudySessionInsert: Codable {
        let userId: UUID
        let bookId: UUID?
        let mode: String
        let totalQuestions: Int
        let correctAnswers: Int
        let masteredCount: Int
        let durationSeconds: Int
        
        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case bookId = "book_id"
            case mode
            case totalQuestions = "total_questions"
            case correctAnswers = "correct_answers"
            case masteredCount = "mastered_count"
            case durationSeconds = "duration_seconds"
        }
    }
    
    /// Saves a study session to Supabase.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - bookId: The book's UUID (nil for "All Words" sessions)
    ///   - mode: Study mode (flashcards, multiple_choice, fill_in_blank)
    ///   - totalQuestions: Total questions in the session
    ///   - correctAnswers: Number of correct answers
    ///   - masteredCount: Number of words newly mastered
    ///   - durationSeconds: Session duration in seconds
    func saveStudySession(
        userId: UUID,
        bookId: UUID?,
        mode: String,
        totalQuestions: Int,
        correctAnswers: Int,
        masteredCount: Int,
        durationSeconds: Int
    ) async throws {
        logger.info("📊 Saving study session: \(mode), \(correctAnswers)/\(totalQuestions)")
        
        let session = StudySessionInsert(
            userId: userId,
            bookId: bookId,
            mode: mode,
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
            masteredCount: masteredCount,
            durationSeconds: durationSeconds
        )
        
        try await client
            .from("study_sessions")
            .insert(session)
            .execute()
        
        logger.info("📊 Study session saved successfully")
    }
    
    // MARK: - User Profile Operations
    
    /// Fetches a user's profile from Supabase.
    /// - Parameter userId: The user's UUID
    /// - Returns: UserProfile or nil if not found
    func fetchUserProfile(for userId: UUID) async throws -> UserProfile? {
        logger.info("👤 Fetching profile for user: \(userId.uuidString.prefix(8))")
        
        let profiles: [UserProfile] = try await client
            .from("user_profiles")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if let profile = profiles.first {
            logger.info("👤 Profile fetched successfully")
            return profile
        } else {
            logger.warning("👤 No profile found for user")
            return nil
        }
    }
    
    /// Creates a new user profile in Supabase.
    /// - Parameter profile: The profile insert model
    func createUserProfile(_ profile: UserProfileInsert) async throws {
        logger.info("👤 Creating profile for user: \(profile.userId.uuidString.prefix(8))")
        
        try await client
            .from("user_profiles")
            .insert(profile)
            .execute()
        
        logger.info("👤 Profile created successfully")
    }
    
    /// Updates a user's profile in Supabase.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - displayName: New display name (optional)
    ///   - avatarUrl: New avatar URL (optional)
    func updateUserProfile(
        userId: UUID,
        displayName: String? = nil,
        avatarUrl: String? = nil
    ) async throws {
        logger.info("👤 Updating profile for user: \(userId.uuidString.prefix(8))")
        
        var updates: [String: String] = [:]
        if let name = displayName {
            updates["display_name"] = name
        }
        if let avatar = avatarUrl {
            updates["avatar_url"] = avatar
        }
        
        guard !updates.isEmpty else {
            logger.debug("👤 No updates to apply")
            return
        }
        
        try await client
            .from("user_profiles")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        logger.info("👤 Profile updated successfully")
    }
    
    /// Updates user profile stats (books, words, mastered, sessions).
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - totalBooks: New total books count
    ///   - totalWords: New total words count
    ///   - masteredWords: New mastered words count
    ///   - totalStudySessions: New total sessions count
    func updateUserProfileStats(
        userId: UUID,
        totalBooks: Int? = nil,
        totalWords: Int? = nil,
        masteredWords: Int? = nil,
        totalStudySessions: Int? = nil
    ) async throws {
        logger.info("👤 Updating stats for user: \(userId.uuidString.prefix(8))")
        
        var updates: [String: Int] = [:]
        if let books = totalBooks {
            updates["total_books"] = books
        }
        if let words = totalWords {
            updates["total_words"] = words
        }
        if let mastered = masteredWords {
            updates["mastered_words"] = mastered
        }
        if let sessions = totalStudySessions {
            updates["total_study_sessions"] = sessions
        }
        
        guard !updates.isEmpty else {
            logger.debug("👤 No stat updates to apply")
            return
        }
        
        try await client
            .from("user_profiles")
            .update(updates)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        logger.info("👤 Stats updated successfully")
    }
    
    /// Increments a user profile stat by a given amount.
    /// Uses RPC call for atomic increment.
    func incrementUserProfileStat(
        userId: UUID,
        stat: String,
        amount: Int = 1
    ) async throws {
        logger.info("👤 Incrementing \(stat) by \(amount) for user: \(userId.uuidString.prefix(8))")
        
        // For simplicity, fetch current value, increment, and update
        // In production, you might use a Postgres function for atomic increment
        if let profile = try await fetchUserProfile(for: userId) {
            var newValue: Int
            switch stat {
            case "total_books":
                newValue = profile.totalBooks + amount
                try await updateUserProfileStats(userId: userId, totalBooks: newValue)
            case "total_words":
                newValue = profile.totalWords + amount
                try await updateUserProfileStats(userId: userId, totalWords: newValue)
            case "mastered_words":
                newValue = profile.masteredWords + amount
                try await updateUserProfileStats(userId: userId, masteredWords: newValue)
            case "total_study_sessions":
                newValue = profile.totalStudySessions + amount
                try await updateUserProfileStats(userId: userId, totalStudySessions: newValue)
            default:
                logger.warning("👤 Unknown stat: \(stat)")
            }
        }
    }
    
    // MARK: - User Settings Operations
    
    /// Fetches user settings from Supabase.
    /// - Parameter userId: The user's UUID
    /// - Returns: UserSettings or nil if not found
    func fetchUserSettings(for userId: UUID) async throws -> UserSettings? {
        logger.info("⚙️ Fetching settings for user: \(userId.uuidString.prefix(8))")
        
        let settings: [UserSettings] = try await client
            .from("user_settings")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        
        if let setting = settings.first {
            logger.info("⚙️ Settings fetched successfully (premium: \(setting.isPremium))")
            return setting
        } else {
            logger.warning("⚙️ No settings found for user")
            return nil
        }
    }
    
    /// Creates new user settings in Supabase.
    /// - Parameter settings: The settings insert model
    func createUserSettings(_ settings: UserSettingsInsert) async throws {
        logger.info("⚙️ Creating settings for user: \(settings.userId.uuidString.prefix(8))")
        
        try await client
            .from("user_settings")
            .insert(settings)
            .execute()
        
        logger.info("⚙️ Settings created successfully")
    }
    
    /// Updates user settings in Supabase.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - update: The fields to update
    func updateUserSettings(userId: UUID, update: UserSettingsUpdate) async throws {
        logger.info("⚙️ Updating settings for user: \(userId.uuidString.prefix(8))")
        
        try await client
            .from("user_settings")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        logger.info("⚙️ Settings updated successfully")
    }
    
    /// Updates premium status in user settings.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - isPremium: Whether user is premium
    ///   - productId: The subscription product ID
    ///   - expiresAt: When the subscription expires
    func updatePremiumStatus(
        userId: UUID,
        isPremium: Bool,
        productId: String? = nil,
        expiresAt: Date? = nil
    ) async throws {
        logger.info("⚙️ Updating premium status for user: \(userId.uuidString.prefix(8)) to \(isPremium)")
        
        var update = UserSettingsUpdate()
        update.isPremium = isPremium
        update.subscriptionProductId = productId
        update.subscriptionExpiresAt = expiresAt
        
        try await updateUserSettings(userId: userId, update: update)
    }
    
    /// Records a purchase restore timestamp.
    /// - Parameter userId: The user's UUID
    func recordPurchaseRestore(userId: UUID) async throws {
        logger.info("⚙️ Recording purchase restore for user: \(userId.uuidString.prefix(8))")
        
        var update = UserSettingsUpdate()
        update.lastRestoredPurchase = Date()
        
        try await updateUserSettings(userId: userId, update: update)
    }
    
    // MARK: - Trial Management
    
    /// Starts the free trial for a user.
    /// Records the trial start date in the backend.
    /// - Parameter userId: The user's UUID
    /// - Returns: True if trial was started, false if user already used trial
    func startFreeTrial(userId: UUID) async throws -> Bool {
        logger.info("🎁 Starting free trial for user: \(userId.uuidString.prefix(8))")
        
        // Check if user already has a trial or subscription
        if let settings = try await fetchUserSettings(for: userId) {
            if settings.isPremium {
                logger.info("🎁 User already has premium subscription")
                return false
            }
            if settings.premiumTrialStartedAt != nil {
                logger.info("🎁 User already used their free trial")
                return false
            }
        }
        
        // Start the trial
        var update = UserSettingsUpdate()
        update.premiumTrialStartedAt = Date()
        
        try await updateUserSettings(userId: userId, update: update)
        logger.info("🎁 Free trial started successfully")
        return true
    }
    
    /// Updates trial and subscription status together.
    /// Use this when syncing StoreKit state to the backend.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - isPremium: Whether user has an active subscription
    ///   - productId: The subscription product ID
    ///   - expiresAt: When the subscription expires
    ///   - trialStartedAt: When the trial was started (if applicable)
    func updateSubscriptionAndTrialStatus(
        userId: UUID,
        isPremium: Bool,
        productId: String? = nil,
        expiresAt: Date? = nil,
        trialStartedAt: Date? = nil
    ) async throws {
        logger.info("⚙️ Updating subscription/trial status for user: \(userId.uuidString.prefix(8))")
        
        var update = UserSettingsUpdate()
        update.isPremium = isPremium
        update.subscriptionProductId = productId
        update.subscriptionExpiresAt = expiresAt
        
        // Only update trial start if provided (don't overwrite existing)
        if let trialStart = trialStartedAt {
            update.premiumTrialStartedAt = trialStart
        }
        
        try await updateUserSettings(userId: userId, update: update)
        logger.info("⚙️ Subscription/trial status updated successfully")
    }
    
    // MARK: - User Onboarding (Create Profile + Settings)
    
    /// Creates both profile and settings for a new user.
    /// Call this after successful signup.
    /// - Parameters:
    ///   - userId: The user's UUID
    ///   - displayName: Optional display name (e.g., from email)
    func createUserOnboarding(userId: UUID, displayName: String? = nil) async throws {
        logger.info("🆕 Creating onboarding data for new user: \(userId.uuidString.prefix(8))")
        
        // Create profile
        let profileInsert = UserProfileInsert(userId: userId, displayName: displayName)
        try await createUserProfile(profileInsert)
        
        // Create settings
        let settingsInsert = UserSettingsInsert(userId: userId)
        try await createUserSettings(settingsInsert)
        
        logger.info("🆕 Onboarding data created successfully")
    }
}

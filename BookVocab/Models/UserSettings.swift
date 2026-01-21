//
//  UserSettings.swift
//  BookVocab
//
//  Data model representing user settings and preferences.
//  Includes premium status and app configuration.
//

import Foundation

/// Represents user settings including premium status and preferences.
/// Syncs with the `user_settings` table in Supabase.
struct UserSettings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// The user's ID (primary key, matches auth.users)
    let userId: UUID
    
    /// Whether the user has an active premium subscription
    var isPremium: Bool
    
    /// The product ID of the active subscription (e.g., "com.bookvocab.premium.monthly")
    var subscriptionProductId: String?
    
    /// When the subscription expires
    var subscriptionExpiresAt: Date?
    
    /// When purchases were last restored
    var lastRestoredPurchase: Date?
    
    /// Whether push notifications are enabled
    var notificationsEnabled: Bool
    
    /// Daily reminder time (stored as HH:mm string for simplicity)
    var dailyReminderTime: String?
    
    /// User's preferred study mode
    var preferredStudyMode: String
    
    /// Feature flags for A/B testing or gradual rollouts
    var featureFlags: [String: Bool]
    
    /// Timestamp when the settings were created
    let createdAt: Date
    
    /// Timestamp when the settings were last updated
    var updatedAt: Date
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isPremium = "is_premium"
        case subscriptionProductId = "subscription_product_id"
        case subscriptionExpiresAt = "subscription_expires_at"
        case lastRestoredPurchase = "last_restored_purchase"
        case notificationsEnabled = "notifications_enabled"
        case dailyReminderTime = "daily_reminder_time"
        case preferredStudyMode = "preferred_study_mode"
        case featureFlags = "feature_flags"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Initialization
    
    /// Creates new UserSettings with default values.
    /// - Parameter userId: The user's UUID from Supabase auth
    init(
        userId: UUID,
        isPremium: Bool = false,
        subscriptionProductId: String? = nil,
        subscriptionExpiresAt: Date? = nil,
        lastRestoredPurchase: Date? = nil,
        notificationsEnabled: Bool = true,
        dailyReminderTime: String? = "08:00",
        preferredStudyMode: String = "flashcards",
        featureFlags: [String: Bool] = [:],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.userId = userId
        self.isPremium = isPremium
        self.subscriptionProductId = subscriptionProductId
        self.subscriptionExpiresAt = subscriptionExpiresAt
        self.lastRestoredPurchase = lastRestoredPurchase
        self.notificationsEnabled = notificationsEnabled
        self.dailyReminderTime = dailyReminderTime
        self.preferredStudyMode = preferredStudyMode
        self.featureFlags = featureFlags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Custom Decoding
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        userId = try container.decode(UUID.self, forKey: .userId)
        isPremium = try container.decode(Bool.self, forKey: .isPremium)
        subscriptionProductId = try container.decodeIfPresent(String.self, forKey: .subscriptionProductId)
        subscriptionExpiresAt = try container.decodeIfPresent(Date.self, forKey: .subscriptionExpiresAt)
        lastRestoredPurchase = try container.decodeIfPresent(Date.self, forKey: .lastRestoredPurchase)
        notificationsEnabled = try container.decode(Bool.self, forKey: .notificationsEnabled)
        preferredStudyMode = try container.decodeIfPresent(String.self, forKey: .preferredStudyMode) ?? "flashcards"
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        
        // Handle daily_reminder_time which comes as TIME type (string like "08:00:00")
        if let timeString = try container.decodeIfPresent(String.self, forKey: .dailyReminderTime) {
            // Extract just HH:mm from potential HH:mm:ss format
            let components = timeString.split(separator: ":")
            if components.count >= 2 {
                dailyReminderTime = "\(components[0]):\(components[1])"
            } else {
                dailyReminderTime = timeString
            }
        } else {
            dailyReminderTime = "08:00"
        }
        
        // Handle feature_flags JSONB - may come as dictionary or empty
        if let flags = try? container.decode([String: Bool].self, forKey: .featureFlags) {
            featureFlags = flags
        } else {
            featureFlags = [:]
        }
    }
    
    // MARK: - Computed Properties
    
    /// Whether the subscription is currently active (not expired)
    var isSubscriptionActive: Bool {
        guard isPremium else { return false }
        guard let expiresAt = subscriptionExpiresAt else { return isPremium }
        return expiresAt > Date()
    }
    
    /// Parsed daily reminder time as Date components
    var reminderTimeComponents: (hour: Int, minute: Int)? {
        guard let timeString = dailyReminderTime else { return nil }
        let parts = timeString.split(separator: ":")
        guard parts.count >= 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        return (hour, minute)
    }
}

// MARK: - Insert Model (for creating new settings)

/// Model for inserting new user settings into Supabase.
struct UserSettingsInsert: Codable {
    let userId: UUID
    var isPremium: Bool
    var subscriptionProductId: String?
    var subscriptionExpiresAt: Date?
    var lastRestoredPurchase: Date?
    var notificationsEnabled: Bool
    var dailyReminderTime: String?
    var preferredStudyMode: String
    var featureFlags: [String: Bool]
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case isPremium = "is_premium"
        case subscriptionProductId = "subscription_product_id"
        case subscriptionExpiresAt = "subscription_expires_at"
        case lastRestoredPurchase = "last_restored_purchase"
        case notificationsEnabled = "notifications_enabled"
        case dailyReminderTime = "daily_reminder_time"
        case preferredStudyMode = "preferred_study_mode"
        case featureFlags = "feature_flags"
    }
    
    /// Creates an insert model with default values for a new user.
    init(userId: UUID) {
        self.userId = userId
        self.isPremium = false
        self.subscriptionProductId = nil
        self.subscriptionExpiresAt = nil
        self.lastRestoredPurchase = nil
        self.notificationsEnabled = true
        self.dailyReminderTime = "08:00"
        self.preferredStudyMode = "flashcards"
        self.featureFlags = [:]
    }
}

// MARK: - Update Model (for partial updates)

/// Model for updating specific user settings fields.
struct UserSettingsUpdate: Codable {
    var isPremium: Bool?
    var subscriptionProductId: String?
    var subscriptionExpiresAt: Date?
    var lastRestoredPurchase: Date?
    var notificationsEnabled: Bool?
    var dailyReminderTime: String?
    var preferredStudyMode: String?
    var featureFlags: [String: Bool]?
    
    enum CodingKeys: String, CodingKey {
        case isPremium = "is_premium"
        case subscriptionProductId = "subscription_product_id"
        case subscriptionExpiresAt = "subscription_expires_at"
        case lastRestoredPurchase = "last_restored_purchase"
        case notificationsEnabled = "notifications_enabled"
        case dailyReminderTime = "daily_reminder_time"
        case preferredStudyMode = "preferred_study_mode"
        case featureFlags = "feature_flags"
    }
}

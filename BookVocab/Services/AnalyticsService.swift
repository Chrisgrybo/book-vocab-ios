//
//  AnalyticsService.swift
//  BookVocab
//
//  Centralized analytics service using Mixpanel.
//  Provides type-safe event tracking for all user interactions.
//
//  Features:
//  - Singleton pattern for easy access
//  - Type-safe event names and properties
//  - Offline event queueing (handled by Mixpanel SDK)
//  - Debug logging in debug builds
//  - User profile management
//  - Revenue and freemium tracking
//
//  Usage:
//    AnalyticsService.shared.track(.bookAdded, properties: ["title": "1984"])
//

import Foundation
import Mixpanel
import os.log

/// Logger for analytics debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "Analytics")

// MARK: - Analytics Events

/// All trackable events in the app.
/// Organized by feature area for easy navigation.
enum AnalyticsEvent: String {
    
    // MARK: - Authentication Events
    case signUp = "Sign Up"
    case login = "Login"
    case logout = "Logout"
    case loginFailed = "Login Failed"
    case signUpFailed = "Sign Up Failed"
    
    // MARK: - Book Management Events
    case bookAdded = "Book Added"
    case bookDeleted = "Book Deleted"
    case bookViewed = "Book Viewed"
    case bookCoverFetched = "Book Cover Fetched"
    case bookSearched = "Book Searched"
    
    // MARK: - Word Management Events
    case wordAdded = "Word Added"
    case wordEdited = "Word Edited"
    case wordDeleted = "Word Deleted"
    case wordLookedUp = "Word Looked Up"
    case wordMasteryToggled = "Word Mastery Toggled"
    case wordsMasteredFromSession = "Words Mastered From Session"
    
    // MARK: - Study Session Events
    case studySessionStarted = "Study Session Started"
    case studySessionCompleted = "Study Session Completed"
    case studySessionExited = "Study Session Exited"
    case flashcardFlipped = "Flashcard Flipped"
    case flashcardSwiped = "Flashcard Swiped"
    case quizAnswerSubmitted = "Quiz Answer Submitted"
    case studySourceSelected = "Study Source Selected"
    
    // MARK: - Ad Events
    case adLoaded = "Ad Loaded"
    case adFailed = "Ad Failed"
    case adDisplayed = "Ad Displayed"
    case adClicked = "Ad Clicked"
    case adDismissed = "Ad Dismissed"
    case interstitialShown = "Interstitial Shown"
    
    // MARK: - Freemium / Revenue Events
    case premiumPurchased = "Premium Purchased"
    case trialStarted = "Trial Started"
    case subscriptionRenewed = "Subscription Renewed"
    case subscriptionCancelled = "Subscription Cancelled"
    case adsRemoved = "Ads Removed"
    case studyModePremiumUnlock = "Study Mode Premium Unlock"
    case purchaseAttempted = "Purchase Attempted"
    case purchaseFailed = "Purchase Failed"
    case purchaseRestored = "Purchase Restored"
    case restorePurchasesAttempted = "Restore Purchases Attempted"
    case restorePurchasesSuccess = "Restore Purchases Success"
    case restorePurchasesFailed = "Restore Purchases Failed"
    case limitExceeded = "Limit Exceeded"
    case limitReached = "Limit Reached"
    case upgradeModalShown = "Upgrade Modal Shown"
    case upgradeModalDismissed = "Upgrade Modal Dismissed"
    
    // MARK: - App Lifecycle Events
    case appOpened = "App Opened"
    case appBackgrounded = "App Backgrounded"
    case appForegrounded = "App Foregrounded"
    case offlineModeEntered = "Offline Mode Entered"
    case onlineModeRestored = "Online Mode Restored"
    
    // MARK: - Error Events
    case errorOccurred = "Error Occurred"
    case networkError = "Network Error"
    case syncError = "Sync Error"
}

// MARK: - Analytics Property Keys

/// Standard property keys for consistent event properties.
enum AnalyticsProperty: String {
    // User properties
    case userId = "user_id"
    case isPremium = "is_premium"
    case premiumPlanType = "premium_plan_type"
    case adFree = "ad_free"
    case totalSpent = "total_spent"
    
    // Book properties
    case bookId = "book_id"
    case bookTitle = "book_title"
    case bookAuthor = "book_author"
    case hasCover = "has_cover"
    
    // Word properties
    case wordId = "word_id"
    case word = "word"
    case definition = "definition"
    case mastered = "mastered"
    case isGlobalWord = "is_global_word"
    
    // Study properties
    case studyMode = "study_mode"
    case studySource = "study_source"
    case wordCount = "word_count"
    case correctCount = "correct_count"
    case incorrectCount = "incorrect_count"
    case masteredCount = "mastered_count"
    case duration = "duration_seconds"
    case scorePercentage = "score_percentage"
    
    // Quiz properties
    case questionType = "question_type"
    case isCorrect = "is_correct"
    case questionIndex = "question_index"
    case totalQuestions = "total_questions"
    
    // Flashcard properties
    case swipeDirection = "swipe_direction"
    case cardIndex = "card_index"
    case totalCards = "total_cards"
    
    // Purchase properties
    case planType = "plan_type"
    case price = "price"
    case currency = "currency"
    case method = "method"
    case durationDays = "duration_days"
    case transactionId = "transaction_id"
    
    // Ad properties
    case adType = "ad_type"
    case adUnitId = "ad_unit_id"
    case placement = "placement"
    
    // Error properties
    case errorType = "error_type"
    case errorMessage = "error_message"
    case errorCode = "error_code"
    
    // General properties
    case timestamp = "timestamp"
    case source = "source"
    case success = "success"
}

// MARK: - Analytics Service

/// Singleton service for tracking analytics events using Mixpanel.
/// Thread-safe and supports offline event queueing.
@MainActor
final class AnalyticsService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AnalyticsService()
    
    // MARK: - Properties
    
    /// Whether analytics is initialized
    @Published private(set) var isInitialized = false
    
    /// Mixpanel instance (lazy loaded)
    private var mixpanel: MixpanelInstance?
    
    /// Whether to log events in debug builds
    #if DEBUG
    private let debugLogging = true
    #else
    private let debugLogging = false
    #endif
    
    // MARK: - Initialization
    
    private init() {
        logger.info("📊 AnalyticsService created")
    }
    
    /// Initializes Mixpanel with the token from Secrets.
    /// Should be called once on app launch.
    func initialize() {
        guard !isInitialized else {
            logger.debug("📊 Analytics already initialized")
            return
        }
        
        let token = Secrets.mixpanelToken
        
        guard !token.isEmpty, token != "your-mixpanel-token" else {
            logger.warning("📊 Mixpanel token not configured - analytics disabled")
            return
        }
        
        logger.info("📊 Initializing Mixpanel...")
        
        // Initialize Mixpanel with offline tracking enabled
        mixpanel = Mixpanel.initialize(
            token: token,
            trackAutomaticEvents: true,
            optOutTrackingByDefault: false
        )
        
        // Configure Mixpanel settings
        mixpanel?.loggingEnabled = debugLogging
        mixpanel?.flushInterval = 60 // Flush events every 60 seconds
        
        isInitialized = true
        logger.info("📊 Mixpanel initialized successfully")
        
        // Track app opened
        track(.appOpened)
    }
    
    // MARK: - Event Tracking
    
    /// Tracks an analytics event with optional properties.
    /// - Parameters:
    ///   - event: The event to track
    ///   - properties: Optional dictionary of event properties
    func track(_ event: AnalyticsEvent, properties: [String: MixpanelType]? = nil) {
        guard isInitialized, let mixpanel = mixpanel else {
            if debugLogging {
                logger.debug("📊 [NOT SENT] \(event.rawValue)")
            }
            return
        }
        
        // Add timestamp to all events
        var allProperties = properties ?? [:]
        allProperties[AnalyticsProperty.timestamp.rawValue] = Date().ISO8601Format()
        
        mixpanel.track(event: event.rawValue, properties: allProperties)
        
        if debugLogging {
            logger.info("📊 Tracked: \(event.rawValue)")
            if let props = properties, !props.isEmpty {
                logger.debug("📊 Properties: \(props.keys.joined(separator: ", "))")
            }
        }
    }
    
    /// Tracks an event with typed property keys.
    /// - Parameters:
    ///   - event: The event to track
    ///   - properties: Dictionary with AnalyticsProperty keys
    func track(_ event: AnalyticsEvent, properties: [AnalyticsProperty: MixpanelType]) {
        let stringProperties = Dictionary(uniqueKeysWithValues: 
            properties.map { ($0.key.rawValue, $0.value) }
        )
        track(event, properties: stringProperties)
    }
    
    // MARK: - User Identification
    
    /// Identifies the user for analytics tracking.
    /// Call this after successful login/signup.
    /// - Parameter userId: The user's unique identifier
    func identify(userId: String) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.identify(distinctId: userId)
        
        if debugLogging {
            logger.info("📊 Identified user: \(userId.prefix(8))...")
        }
    }
    
    /// Clears user identification on logout.
    func reset() {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.reset()
        
        if debugLogging {
            logger.info("📊 User identity reset")
        }
    }
    
    // MARK: - User Profile
    
    /// Sets a property on the user's profile.
    /// - Parameters:
    ///   - property: The property key
    ///   - value: The property value
    func setUserProperty(_ property: AnalyticsProperty, value: MixpanelType) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.people.set(property: property.rawValue, to: value)
        
        if debugLogging {
            logger.debug("📊 Set user property: \(property.rawValue) = \(String(describing: value))")
        }
    }
    
    /// Sets multiple properties on the user's profile.
    /// - Parameter properties: Dictionary of properties to set
    func setUserProperties(_ properties: [AnalyticsProperty: MixpanelType]) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        let stringProperties = Dictionary(uniqueKeysWithValues:
            properties.map { ($0.key.rawValue, $0.value) }
        )
        
        mixpanel.people.set(properties: stringProperties)
        
        if debugLogging {
            logger.debug("📊 Set user properties: \(stringProperties.keys)")
        }
    }
    
    /// Increments a numeric property on the user's profile.
    /// - Parameters:
    ///   - property: The property to increment
    ///   - amount: The amount to increment by (default: 1)
    func incrementUserProperty(_ property: AnalyticsProperty, by amount: Double = 1) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.people.increment(property: property.rawValue, by: amount)
        
        if debugLogging {
            logger.debug("📊 Incremented \(property.rawValue) by \(amount)")
        }
    }
    
    // MARK: - Revenue Tracking
    
    /// Tracks a revenue event (purchase/subscription).
    /// - Parameters:
    ///   - amount: The purchase amount
    ///   - properties: Additional properties for the purchase
    func trackRevenue(amount: Double, properties: [AnalyticsProperty: MixpanelType]? = nil) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        // Track revenue on People profile
        if let props = properties {
            let stringProperties = Dictionary(uniqueKeysWithValues:
                props.map { ($0.key.rawValue, $0.value) }
            )
            mixpanel.people.trackCharge(amount: amount, properties: stringProperties)
        } else {
            mixpanel.people.trackCharge(amount: amount)
        }
        
        if debugLogging {
            logger.info("📊 💰 Tracked revenue: $\(String(format: "%.2f", amount))")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Updates user profile after a premium purchase.
    /// - Parameters:
    ///   - planType: The plan type (monthly/annual)
    ///   - price: The purchase price
    func updatePremiumStatus(planType: String, price: Double) {
        setUserProperties([
            .isPremium: true,
            .premiumPlanType: planType,
            .adFree: true
        ])
        
        incrementUserProperty(.totalSpent, by: price)
        
        if debugLogging {
            logger.info("📊 Updated premium status: \(planType), $\(price)")
        }
    }
    
    /// Clears premium status (e.g., subscription cancelled/expired).
    func clearPremiumStatus() {
        setUserProperties([
            .isPremium: false,
            .premiumPlanType: "",
            .adFree: false
        ])
        
        if debugLogging {
            logger.info("📊 Cleared premium status")
        }
    }
    
    // MARK: - Time Tracking
    
    /// Starts timing an event (for duration tracking).
    /// - Parameter event: The event to time
    func timeEvent(_ event: AnalyticsEvent) {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.time(event: event.rawValue)
        
        if debugLogging {
            logger.debug("📊 Started timing: \(event.rawValue)")
        }
    }
    
    // MARK: - Flush
    
    /// Forces an immediate flush of queued events.
    /// Useful before app termination or significant state changes.
    func flush() {
        guard isInitialized, let mixpanel = mixpanel else { return }
        
        mixpanel.flush()
        
        if debugLogging {
            logger.debug("📊 Flushed events to Mixpanel")
        }
    }
}

// MARK: - Analytics Convenience Extensions

extension AnalyticsService {
    
    // MARK: - Authentication Tracking
    
    /// Tracks a successful sign up.
    func trackSignUp(userId: String) {
        identify(userId: userId)
        track(.signUp, properties: [.userId: userId])
        setUserProperty(.isPremium, value: false)
    }
    
    /// Tracks a successful login.
    func trackLogin(userId: String) {
        identify(userId: userId)
        track(.login, properties: [.userId: userId])
    }
    
    /// Tracks a logout.
    func trackLogout() {
        track(.logout)
        reset()
    }
    
    // MARK: - Book Tracking
    
    /// Tracks a book being added.
    func trackBookAdded(title: String, author: String, hasCover: Bool) {
        track(.bookAdded, properties: [
            .bookTitle: title,
            .bookAuthor: author,
            .hasCover: hasCover
        ])
    }
    
    /// Tracks a book being deleted.
    func trackBookDeleted(title: String) {
        track(.bookDeleted, properties: [.bookTitle: title])
    }
    
    /// Tracks a book being viewed.
    func trackBookViewed(title: String, wordCount: Int) {
        track(.bookViewed, properties: [
            .bookTitle: title,
            .wordCount: wordCount
        ])
    }
    
    // MARK: - Word Tracking
    
    /// Tracks a word being added.
    func trackWordAdded(word: String, bookTitle: String?, isGlobal: Bool) {
        var props: [AnalyticsProperty: MixpanelType] = [
            .word: word,
            .isGlobalWord: isGlobal
        ]
        if let book = bookTitle {
            props[.bookTitle] = book
        }
        track(.wordAdded, properties: props)
    }
    
    /// Tracks a word lookup.
    func trackWordLookedUp(word: String, success: Bool) {
        track(.wordLookedUp, properties: [
            .word: word,
            .success: success
        ])
    }
    
    /// Tracks word mastery toggle.
    func trackMasteryToggled(word: String, mastered: Bool) {
        track(.wordMasteryToggled, properties: [
            .word: word,
            .mastered: mastered
        ])
    }
    
    // MARK: - Study Session Tracking
    
    /// Tracks the start of a study session.
    func trackStudySessionStarted(mode: String, source: String, wordCount: Int) {
        timeEvent(.studySessionCompleted) // Start timing
        track(.studySessionStarted, properties: [
            .studyMode: mode,
            .studySource: source,
            .wordCount: wordCount
        ])
    }
    
    /// Tracks the completion of a study session.
    func trackStudySessionCompleted(
        mode: String,
        source: String,
        wordCount: Int,
        correctCount: Int,
        masteredCount: Int,
        durationSeconds: TimeInterval
    ) {
        track(.studySessionCompleted, properties: [
            .studyMode: mode,
            .studySource: source,
            .wordCount: wordCount,
            .correctCount: correctCount,
            .masteredCount: masteredCount,
            .duration: Int(durationSeconds),
            .scorePercentage: wordCount > 0 ? Int((Double(correctCount) / Double(wordCount)) * 100) : 0
        ])
    }
    
    /// Tracks a quiz answer submission.
    func trackQuizAnswer(isCorrect: Bool, questionIndex: Int, totalQuestions: Int, questionType: String) {
        track(.quizAnswerSubmitted, properties: [
            .isCorrect: isCorrect,
            .questionIndex: questionIndex,
            .totalQuestions: totalQuestions,
            .questionType: questionType
        ])
    }
    
    /// Tracks a flashcard swipe.
    func trackFlashcardSwipe(direction: String, cardIndex: Int, totalCards: Int) {
        track(.flashcardSwiped, properties: [
            .swipeDirection: direction,
            .cardIndex: cardIndex,
            .totalCards: totalCards
        ])
    }
    
    // MARK: - Purchase Tracking
    
    /// Tracks a premium purchase.
    func trackPremiumPurchase(planType: String, price: Double, currency: String, transactionId: String?) {
        var props: [AnalyticsProperty: MixpanelType] = [
            .planType: planType,
            .price: price,
            .currency: currency
        ]
        if let txId = transactionId {
            props[.transactionId] = txId
        }
        
        track(.premiumPurchased, properties: props)
        trackRevenue(amount: price, properties: props)
        updatePremiumStatus(planType: planType, price: price)
    }
    
    /// Tracks ad removal.
    func trackAdsRemoved(method: String, planType: String) {
        track(.adsRemoved, properties: [
            .method: method,
            .planType: planType
        ])
        setUserProperty(.adFree, value: true)
    }
    
    /// Tracks a subscription cancellation.
    func trackSubscriptionCancelled(planType: String) {
        track(.subscriptionCancelled, properties: [.planType: planType])
        clearPremiumStatus()
    }
    
    // MARK: - Ad Tracking
    
    /// Tracks an interstitial ad being shown.
    func trackInterstitialShown(placement: String) {
        track(.interstitialShown, properties: [
            .adType: "interstitial",
            .placement: placement
        ])
    }
    
    /// Tracks an ad being dismissed.
    func trackAdDismissed(adType: String, placement: String) {
        track(.adDismissed, properties: [
            .adType: adType,
            .placement: placement
        ])
    }
}


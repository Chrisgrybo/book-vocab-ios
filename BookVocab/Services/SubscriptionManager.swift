//
//  SubscriptionManager.swift
//  BookVocab
//
//  Manages in-app purchases and subscription status using StoreKit 2.
//  Handles premium tier unlocking, restore purchases, and persistence.
//
//  Freemium Model:
//  - Free: 6 books, 16 words/book, Flashcards only, ads enabled
//  - Premium: Unlimited books/words, full study modes, no ads
//

import Foundation
import StoreKit
import SwiftUI
import os.log

/// Logger for subscription operations
private let logger = Logger(subsystem: "com.bookvocab.app", category: "SubscriptionManager")

// MARK: - Freemium Limits

/// Constants defining free tier limits
enum FreemiumLimits {
    /// Maximum number of books for free users
    static let maxBooks: Int = 6
    
    /// Maximum number of words per book for free users
    static let maxWordsPerBook: Int = 16
    
    /// Study modes available for free users
    static let freeStudyModes: Set<StudyMode> = [.flashcards]
    
    /// All study modes (premium)
    static let allStudyModes: Set<StudyMode> = [.flashcards, .multipleChoice, .fillInBlank]
}

// Note: StudyMode enum is defined in StudyViewModel.swift

// MARK: - Subscription Product IDs

/// Product identifiers for in-app purchases
enum SubscriptionProduct: String, CaseIterable {
    /// Monthly subscription ($1.99)
    case monthlyPremium = "com.bookvocab.premium.monthly"
    
    var displayName: String {
        switch self {
        case .monthlyPremium: return "Premium Monthly"
        }
    }
    
    var price: String {
        switch self {
        case .monthlyPremium: return "$1.99/month"
        }
    }
}

// MARK: - Subscription Manager

/// Singleton manager for handling in-app purchases and subscription status.
@MainActor
class SubscriptionManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = SubscriptionManager()
    
    // MARK: - Published Properties
    
    /// Whether the user has an active premium subscription
    @Published private(set) var isPremium: Bool = false
    
    /// The currently active subscription product
    @Published private(set) var activeSubscription: Product?
    
    /// Available products for purchase
    @Published private(set) var products: [Product] = []
    
    /// Whether a purchase/restore is in progress
    @Published var isProcessing: Bool = false
    
    /// Error message to display
    @Published var errorMessage: String?
    
    /// Whether to show the upgrade modal
    @Published var showUpgradeModal: Bool = false
    
    /// Reason for showing the upgrade modal
    @Published var upgradeReason: UpgradeReason = .generic
    
    // MARK: - Persisted State
    
    /// Persisted premium status (backup for when StoreKit check fails)
    @AppStorage("isPremium") private var persistedPremiumStatus: Bool = false
    
    /// Subscription expiration date (for display purposes)
    @AppStorage("subscriptionExpirationDate") private var subscriptionExpirationTimestamp: Double = 0
    
    // MARK: - Private Properties
    
    /// Task for listening to transaction updates
    private var updateListenerTask: Task<Void, Error>?
    
    /// The current user's ID for syncing to backend
    private var currentUserId: UUID?
    
    /// Reference to the Supabase service
    private let supabaseService = SupabaseService.shared
    
    /// Network monitor for checking connectivity
    private let networkMonitor = NetworkMonitor.shared
    
    // MARK: - Initialization
    
    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        
        // Load products and check subscription status
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
        
        logger.info("💎 SubscriptionManager initialized")
    }
    
    // MARK: - User Management
    
    /// Sets the current user ID for syncing premium status to backend.
    /// - Parameter userId: The user's UUID
    func setUserId(_ userId: UUID) {
        self.currentUserId = userId
        logger.debug("💎 User ID set: \(userId.uuidString.prefix(8))")
    }
    
    /// Clears the current user ID (on sign out).
    func clearUserId() {
        self.currentUserId = nil
        logger.debug("💎 User ID cleared")
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Product Loading
    
    /// Loads available products from the App Store
    func loadProducts() async {
        logger.debug("💎 Loading products...")
        
        do {
            let productIds = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: productIds)
            
            logger.info("💎 Loaded \(self.products.count) products")
            
            for product in products {
                logger.debug("💎 Product: \(product.displayName) - \(product.displayPrice)")
            }
        } catch {
            logger.error("💎 Failed to load products: \(error.localizedDescription)")
            errorMessage = "Failed to load subscription options"
        }
    }
    
    // MARK: - Purchase
    
    /// Initiates a purchase for the given product
    /// - Parameter product: The product to purchase
    func purchase(_ product: Product) async {
        logger.info("💎 Initiating purchase for: \(product.displayName)")
        
        isProcessing = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                
                // Update subscription status
                await updateSubscriptionStatus()
                
                // Finish the transaction
                await transaction.finish()
                
                logger.info("💎 Purchase successful!")
                
                // Track analytics
                AnalyticsService.shared.trackPremiumPurchase(
                    planType: "monthly",
                    price: NSDecimalNumber(decimal: product.price).doubleValue,
                    currency: product.priceFormatStyle.currencyCode ?? "USD",
                    transactionId: String(transaction.id)
                )
                
            case .userCancelled:
                logger.debug("💎 User cancelled purchase")
                
            case .pending:
                logger.debug("💎 Purchase pending approval")
                errorMessage = "Purchase is pending approval"
                
            @unknown default:
                logger.warning("💎 Unknown purchase result")
            }
        } catch {
            logger.error("💎 Purchase failed: \(error.localizedDescription)")
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            
            // Track failed purchase
            AnalyticsService.shared.track(.purchaseFailed, properties: [
                "error": error.localizedDescription
            ])
        }
        
        isProcessing = false
    }
    
    /// Purchases the monthly premium subscription
    func purchaseMonthlyPremium() async {
        guard let product = products.first(where: { $0.id == SubscriptionProduct.monthlyPremium.rawValue }) else {
            logger.error("💎 Monthly premium product not found")
            errorMessage = "Subscription not available"
            return
        }
        
        await purchase(product)
    }
    
    // MARK: - Restore Purchases
    
    /// Restores previous purchases
    func restorePurchases() async {
        logger.info("💎 Restoring purchases...")
        
        isProcessing = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            
            // Record restore timestamp in backend
            if let userId = currentUserId, networkMonitor.isConnected {
                do {
                    try await supabaseService.recordPurchaseRestore(userId: userId)
                    logger.info("💎 Purchase restore recorded in backend")
                } catch {
                    logger.error("💎 Failed to record restore: \(error.localizedDescription)")
                }
            }
            
            if isPremium {
                logger.info("💎 Purchases restored successfully - Premium active")
                
                // Track analytics
                AnalyticsService.shared.track(.purchaseRestored, properties: [
                    "status": "success",
                    "is_premium": true
                ])
            } else {
                logger.info("💎 No active subscriptions found")
                errorMessage = "No active subscriptions found"
                
                AnalyticsService.shared.track(.purchaseRestored, properties: [
                    "status": "no_subscription",
                    "is_premium": false
                ])
            }
        } catch {
            logger.error("💎 Restore failed: \(error.localizedDescription)")
            errorMessage = "Failed to restore purchases"
            
            AnalyticsService.shared.track(.purchaseRestored, properties: [
                "status": "failed",
                "error": error.localizedDescription
            ])
        }
        
        isProcessing = false
    }
    
    // MARK: - Subscription Status
    
    /// Updates the current subscription status
    func updateSubscriptionStatus() async {
        logger.debug("💎 Updating subscription status...")
        
        var hasActiveSubscription = false
        var productId: String? = nil
        var expirationDate: Date? = nil
        
        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productType == .autoRenewable {
                    hasActiveSubscription = true
                    productId = transaction.productID
                    
                    // Find the corresponding product
                    if let product = products.first(where: { $0.id == transaction.productID }) {
                        activeSubscription = product
                    }
                    
                    // Store expiration date
                    if let expDate = transaction.expirationDate {
                        subscriptionExpirationTimestamp = expDate.timeIntervalSince1970
                        expirationDate = expDate
                    }
                    
                    logger.info("💎 Active subscription found: \(transaction.productID)")
                }
            } catch {
                logger.error("💎 Transaction verification failed: \(error.localizedDescription)")
            }
        }
        
        // Update premium status
        let previousStatus = isPremium
        isPremium = hasActiveSubscription
        persistedPremiumStatus = hasActiveSubscription
        
        if !hasActiveSubscription {
            activeSubscription = nil
        }
        
        logger.info("💎 Premium status: \(self.isPremium)")
        
        // Sync to backend if status changed
        if previousStatus != hasActiveSubscription {
            await syncPremiumStatusToBackend(
                isPremium: hasActiveSubscription,
                productId: productId,
                expiresAt: expirationDate
            )
        }
    }
    
    /// Syncs premium status to the Supabase backend.
    private func syncPremiumStatusToBackend(isPremium: Bool, productId: String?, expiresAt: Date?) async {
        guard let userId = currentUserId else {
            logger.debug("💎 No user ID - skipping backend sync")
            return
        }
        
        guard networkMonitor.isConnected else {
            logger.warning("💎 Offline - premium status will sync when online")
            return
        }
        
        logger.info("💎 Syncing premium status to backend: \(isPremium)")
        
        do {
            try await supabaseService.updatePremiumStatus(
                userId: userId,
                isPremium: isPremium,
                productId: productId,
                expiresAt: expiresAt
            )
            logger.info("💎 Premium status synced to backend successfully")
        } catch {
            logger.error("💎 Failed to sync premium status: \(error.localizedDescription)")
        }
    }
    
    /// Loads premium status from the backend (for cross-device sync).
    /// - Parameter settings: The user settings from the backend
    func loadPremiumStatusFromBackend(_ settings: UserSettings) {
        logger.info("💎 Loading premium status from backend: \(settings.isPremium)")
        
        // Only update if StoreKit doesn't have an active subscription
        // (StoreKit is the source of truth for active subscriptions)
        if !isPremium && settings.isPremium {
            // Backend says premium but StoreKit doesn't
            // This could mean:
            // 1. Subscription was purchased on another device
            // 2. Subscription expired and backend hasn't been updated
            // We should verify with StoreKit
            Task {
                await updateSubscriptionStatus()
            }
        }
    }
    
    // MARK: - Transaction Listener
    
    /// Listens for transaction updates (renewals, cancellations, etc.)
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                    
                    await MainActor.run {
                        logger.info("💎 Transaction update processed")
                    }
                } catch {
                    await MainActor.run {
                        logger.error("💎 Transaction update failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Verification
    
    /// Verifies a transaction result
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    // MARK: - Limit Checks
    
    /// Checks if the user can add more books
    /// - Parameter currentCount: Current number of books
    /// - Returns: Whether the user can add another book
    func canAddBook(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < FreemiumLimits.maxBooks
    }
    
    /// Checks if the user can add more words to a book
    /// - Parameter currentCount: Current number of words in the book
    /// - Returns: Whether the user can add another word
    func canAddWord(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < FreemiumLimits.maxWordsPerBook
    }
    
    /// Checks if a study mode is available to the user
    /// - Parameter mode: The study mode to check
    /// - Returns: Whether the mode is available
    func isStudyModeAvailable(_ mode: StudyMode) -> Bool {
        if isPremium { return true }
        return FreemiumLimits.freeStudyModes.contains(mode)
    }
    
    /// Returns available study modes for the current user
    var availableStudyModes: [StudyMode] {
        if isPremium {
            return StudyMode.allCases
        }
        return Array(FreemiumLimits.freeStudyModes)
    }
    
    // MARK: - Upgrade Prompts
    
    /// Shows the upgrade modal with a specific reason
    /// - Parameter reason: Why the upgrade is being prompted
    func promptUpgrade(reason: UpgradeReason) {
        upgradeReason = reason
        showUpgradeModal = true
        
        // Track the limit hit
        AnalyticsService.shared.track(.limitReached, properties: [
            "reason": reason.rawValue,
            "is_premium": isPremium
        ])
        
        logger.info("💎 Showing upgrade prompt: \(reason.rawValue)")
    }
    
    /// Remaining books the user can add (free tier)
    var remainingBooks: Int {
        // This would need the actual count from BooksViewModel
        // For now, return the max
        return FreemiumLimits.maxBooks
    }
    
    /// Remaining words per book (free tier)
    var remainingWordsPerBook: Int {
        return FreemiumLimits.maxWordsPerBook
    }
}

// MARK: - Upgrade Reason

/// Reasons for prompting an upgrade
enum UpgradeReason: String {
    case bookLimit = "book_limit"
    case wordLimit = "word_limit"
    case studyModeRestricted = "study_mode_restricted"
    case generic = "generic"
    
    var title: String {
        switch self {
        case .bookLimit:
            return "Book Limit Reached"
        case .wordLimit:
            return "Word Limit Reached"
        case .studyModeRestricted:
            return "Premium Study Mode"
        case .generic:
            return "Unlock Premium"
        }
    }
    
    var message: String {
        switch self {
        case .bookLimit:
            return "Free users can save up to \(FreemiumLimits.maxBooks) books. Upgrade to Premium for unlimited books!"
        case .wordLimit:
            return "Free users can save up to \(FreemiumLimits.maxWordsPerBook) words per book. Upgrade to Premium for unlimited words!"
        case .studyModeRestricted:
            return "Multiple Choice and Fill-in-the-Blank modes are Premium features. Upgrade to unlock all study modes!"
        case .generic:
            return "Get unlimited books, words, and all study modes with Premium!"
        }
    }
    
    var icon: String {
        switch self {
        case .bookLimit: return "books.vertical"
        case .wordLimit: return "textformat.abc"
        case .studyModeRestricted: return "brain.head.profile"
        case .generic: return "star.fill"
        }
    }
}

// MARK: - Store Errors

/// Errors that can occur during store operations
enum StoreError: Error, LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed
    
    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        case .productNotFound:
            return "Product not found"
        case .purchaseFailed:
            return "Purchase failed"
        }
    }
}


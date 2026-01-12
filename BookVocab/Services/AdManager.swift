//
//  AdManager.swift
//  BookVocab
//
//  Singleton manager for AdMob ads (MREC banners and interstitials).
//  Handles ad initialization, loading, and presentation.
//
//  Features:
//  - Initialize Google Mobile Ads SDK
//  - Load and cache interstitial ads with retry logic
//  - Premium ad-removal check
//  - Comprehensive debug logging for ad events
//

import Foundation
import SwiftUI
import GoogleMobileAds
import os.log

/// Logger for AdManager debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "AdManager")

/// Singleton manager for all AdMob ad operations.
/// Handles initialization, loading, and presentation of ads.
@MainActor
class AdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = AdManager()
    
    // MARK: - Ad Unit IDs (Test IDs - Replace with production IDs before release)
    
    /// Test MREC banner ad unit ID
    /// Replace with your production ad unit ID: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
    static let mrecAdUnitID = "ca-app-pub-3940256099942544/6300978111" // Test banner
    
    /// Test interstitial ad unit ID
    /// Replace with your production ad unit ID: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY
    static let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712" // Test interstitial
    
    // MARK: - Published Properties
    
    /// Whether the user has premium (no ads)
    /// This reads from SubscriptionManager for consistency
    var isPremium: Bool {
        SubscriptionManager.shared.isPremium
    }
    
    /// Whether an interstitial ad is ready to show
    @Published var isInterstitialReady: Bool = false
    
    /// Whether the SDK has been initialized
    @Published var isInitialized: Bool = false
    
    // MARK: - Private Properties
    
    /// Cached interstitial ad
    private var interstitialAd: InterstitialAd?
    
    /// Delegate for interstitial presentation
    private var interstitialDelegate: InterstitialAdDelegate?
    
    /// Track load attempts for retry logic
    private var loadAttempts = 0
    private let maxLoadAttempts = 3
    
    /// Timer for retry loading
    private var retryTimer: Timer?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        logger.info("🎯 AdManager initialized")
    }
    
    // MARK: - SDK Initialization
    
    /// Initializes the Google Mobile Ads SDK.
    /// Should be called once on app launch.
    func initialize() {
        guard !isInitialized else {
            logger.debug("🎯 AdManager already initialized, skipping")
            return
        }
        
        logger.info("🎯 Initializing Google Mobile Ads SDK...")
        logger.info("🎯 Using interstitial ad unit: \(AdManager.interstitialAdUnitID)")
        logger.info("🎯 Using MREC ad unit: \(AdManager.mrecAdUnitID)")
        
        MobileAds.shared.start { [weak self] status in
            Task { @MainActor in
                self?.isInitialized = true
                logger.info("✅ Google Mobile Ads SDK initialized successfully")
                
                // Log adapter status for debugging
                logger.info("🎯 Adapter statuses: \(String(describing: status))")
                
                // Preload an interstitial ad
                self?.loadInterstitialAd()
            }
        }
    }
    
    // MARK: - Interstitial Ads
    
    /// Loads an interstitial ad into the cache.
    /// Called automatically after initialization and after showing an ad.
    func loadInterstitialAd() {
        guard !isPremium else {
            logger.debug("🎯 Premium user - skipping interstitial ad load")
            return
        }
        
        guard loadAttempts < maxLoadAttempts else {
            logger.warning("🎯 Max load attempts (\(self.maxLoadAttempts)) reached. Will retry later.")
            // Schedule a retry after 60 seconds
            scheduleRetryLoad(delay: 60)
            return
        }
        
        // Don't reload if we already have an ad
        guard interstitialAd == nil else {
            logger.debug("🎯 Interstitial already loaded, skipping")
            return
        }
        
        loadAttempts += 1
        logger.info("🎯 Loading interstitial ad (attempt \(self.loadAttempts)/\(self.maxLoadAttempts))...")
        
        let request = Request()
        
        InterstitialAd.load(
            with: Self.interstitialAdUnitID,
            request: request
        ) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                if let error = error {
                    logger.error("❌ Failed to load interstitial ad: \(error.localizedDescription)")
                    self.isInterstitialReady = false
                    
                    // Retry with exponential backoff
                    let delay = pow(2.0, Double(self.loadAttempts)) // 2, 4, 8 seconds
                    self.scheduleRetryLoad(delay: delay)
                    return
                }
                
                self.interstitialAd = ad
                self.isInterstitialReady = true
                self.loadAttempts = 0 // Reset on success
                logger.info("✅ Interstitial ad loaded successfully and ready to show")
            }
        }
    }
    
    /// Schedules a retry for loading an interstitial ad
    private func scheduleRetryLoad(delay: TimeInterval) {
        retryTimer?.invalidate()
        logger.debug("🎯 Scheduling interstitial reload in \(delay) seconds")
        
        retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.loadAttempts = 0 // Reset attempts for new cycle
                self?.loadInterstitialAd()
            }
        }
    }
    
    /// Shows the cached interstitial ad if available and user is not premium.
    /// - Parameter viewController: The view controller to present from
    /// - Parameter completion: Called when the ad is dismissed or if showing failed
    func showInterstitial(from viewController: UIViewController, completion: (() -> Void)? = nil) {
        logger.info("🎯 showInterstitial called - isPremium: \(self.isPremium), hasAd: \(self.interstitialAd != nil)")
        
        guard !isPremium else {
            logger.debug("🎯 Premium user - skipping interstitial ad")
            completion?()
            return
        }
        
        guard let interstitialAd = interstitialAd else {
            logger.warning("⚠️ No interstitial ad available to show. Loading one for next time...")
            completion?()
            // Try to load another ad for next time
            loadAttempts = 0
            loadInterstitialAd()
            return
        }
        
        logger.info("🎯 Presenting interstitial ad from view controller: \(type(of: viewController))")
        
        // Create delegate to handle ad dismissal
        let delegate = InterstitialAdDelegate(
            onDismiss: { [weak self] in
                logger.info("✅ Interstitial ad dismissed by user")
                completion?()
                // Load another ad for next time
                Task { @MainActor in
                    self?.loadAttempts = 0
                    self?.loadInterstitialAd()
                }
            },
            onFailedToPresent: { [weak self] error in
                logger.error("❌ Interstitial failed to present: \(error)")
                completion?()
                // Load another ad for next time
                Task { @MainActor in
                    self?.loadAttempts = 0
                    self?.loadInterstitialAd()
                }
            }
        )
        
        self.interstitialDelegate = delegate
        interstitialAd.fullScreenContentDelegate = delegate
        
        // Present the ad
        interstitialAd.present(from: viewController)
        
        // Clear reference after initiating presentation
        self.interstitialAd = nil
        self.isInterstitialReady = false
        
        logger.info("🎯 Interstitial ad presentation initiated")
    }
    
    /// Shows interstitial ad after a delay (for post-session flow).
    /// Ensures ad is loaded before attempting to show.
    /// - Parameters:
    ///   - delay: Delay in seconds before showing the ad
    ///   - viewController: The view controller to present from
    ///   - completion: Called when the ad is dismissed
    func showInterstitialAfterDelay(
        _ delay: TimeInterval = 2.5,
        from viewController: UIViewController,
        completion: (() -> Void)? = nil
    ) {
        logger.info("🎯 showInterstitialAfterDelay called - delay: \(delay)s, isPremium: \(self.isPremium)")
        
        guard !isPremium else {
            logger.debug("🎯 Premium user - skipping delayed interstitial")
            completion?()
            return
        }
        
        // If no ad ready, try to load one
        if interstitialAd == nil {
            logger.info("🎯 No ad ready, attempting to load before delay...")
            loadAttempts = 0
            loadInterstitialAd()
        }
        
        logger.debug("🎯 Scheduling interstitial ad to show in \(delay) seconds")
        
        Task {
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            await MainActor.run {
                logger.info("🎯 Delay complete. Ad ready: \(self.interstitialAd != nil)")
                showInterstitial(from: viewController, completion: completion)
            }
        }
    }
    
    // MARK: - Utility
    
    /// Returns the root view controller for ad presentation.
    func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            logger.warning("⚠️ Could not get root view controller - no window scene")
            return nil
        }
        
        // Get the topmost presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        logger.debug("🎯 Found top view controller: \(type(of: topController))")
        return topController
    }
    
    /// Force preload an ad (useful before starting a study session)
    func preloadInterstitialIfNeeded() {
        guard !isPremium, interstitialAd == nil else { return }
        logger.info("🎯 Preloading interstitial for upcoming session...")
        loadAttempts = 0
        loadInterstitialAd()
    }
}

// MARK: - Interstitial Ad Delegate

/// Delegate class to handle interstitial ad events.
private class InterstitialAdDelegate: NSObject, FullScreenContentDelegate {
    
    private let onDismiss: () -> Void
    private let onFailedToPresent: (String) -> Void
    
    init(onDismiss: @escaping () -> Void, onFailedToPresent: @escaping (String) -> Void = { _ in }) {
        self.onDismiss = onDismiss
        self.onFailedToPresent = onFailedToPresent
        super.init()
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        logger.debug("🎯 adDidDismissFullScreenContent")
        onDismiss()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        logger.error("❌ didFailToPresentFullScreenContentWithError: \(error.localizedDescription)")
        onFailedToPresent(error.localizedDescription)
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        logger.info("🎯 adWillPresentFullScreenContent - Ad is about to display")
    }
    
    func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        logger.info("✅ adDidRecordImpression - Ad impression recorded")
    }
    
    func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        logger.info("✅ adDidRecordClick - User clicked the ad")
    }
}

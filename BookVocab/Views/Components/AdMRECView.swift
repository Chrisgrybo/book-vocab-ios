//
//  AdMRECView.swift
//  BookVocab
//
//  Reusable SwiftUI view for displaying MREC (300x250) banner ads.
//  Uses UIViewRepresentable to wrap BannerView.
//
//  Features:
//  - 300x250 MREC format
//  - Auto-reload on appear
//  - Premium user check (returns EmptyView)
//  - Debug logging for load/fail events
//

import SwiftUI
import GoogleMobileAds
import os.log

/// Logger for AdMRECView debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "AdMRECView")

// MARK: - MREC Banner View

/// A SwiftUI view that displays an MREC (300x250) banner ad.
/// Automatically hides for premium users.
struct AdMRECView: View {
    
    /// Whether the user has premium (no ads)
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    var body: some View {
        if isPremium {
            // Premium users don't see ads
            EmptyView()
        } else {
            MRECBannerRepresentable()
                .frame(width: 300, height: 250)
                .frame(maxWidth: .infinity) // Center horizontally
                .padding(.vertical, AppSpacing.md)
        }
    }
}

// MARK: - UIViewRepresentable Wrapper

/// UIViewRepresentable wrapper for BannerView.
struct MRECBannerRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeMediumRectangle)
        
        bannerView.adUnitID = AdManager.mrecAdUnitID
        bannerView.delegate = context.coordinator
        
        // Get root view controller for ad requests
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        // Load the ad
        logger.debug("📢 MREC: Loading ad...")
        bannerView.load(Request())
        
        return bannerView
    }
    
    func updateUIView(_ bannerView: BannerView, context: Context) {
        // Reload ad when view updates (e.g., on appear)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, BannerViewDelegate {
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            logger.info("📢 MREC: Ad loaded successfully")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            logger.error("📢 MREC: Failed to load ad: \(error.localizedDescription)")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            logger.debug("📢 MREC: Will present screen")
        }
        
        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            logger.debug("📢 MREC: Will dismiss screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            logger.debug("📢 MREC: Did dismiss screen")
        }
    }
}

// MARK: - Conditional Ad View Helper

/// A helper view that conditionally shows an MREC ad at specific intervals in a list.
/// Use this to insert ads every N items in a ForEach loop.
struct ConditionalAdView: View {
    
    /// The index of the current item in the list
    let index: Int
    
    /// Show ad after every N items (e.g., 5 means show ad after items 4, 9, 14...)
    let interval: Int
    
    /// Minimum number of items required to show any ads
    let minimumItems: Int
    
    /// Total number of items in the list
    let totalItems: Int
    
    /// Whether the user has premium (no ads)
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    init(
        index: Int,
        interval: Int = 5,
        minimumItems: Int = 5,
        totalItems: Int
    ) {
        self.index = index
        self.interval = interval
        self.minimumItems = minimumItems
        self.totalItems = totalItems
    }
    
    var body: some View {
        // Show ad if:
        // - Not premium
        // - Total items >= minimum
        // - Index is at the right interval (after every N items)
        // - Not at the very last position (avoid ad at the end)
        if !isPremium &&
           totalItems >= minimumItems &&
           (index + 1) % interval == 0 &&
           index < totalItems - 1 {
            AdMRECView()
        }
    }
}

// MARK: - Preview

#Preview("MREC Banner") {
    VStack {
        Text("Content above ad")
            .padding()
        
        AdMRECView()
        
        Text("Content below ad")
            .padding()
    }
    .background(AppColors.groupedBackground)
}

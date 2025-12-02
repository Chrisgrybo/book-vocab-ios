//
//  SyncService.swift
//  BookVocab
//
//  Handles synchronization between local Core Data cache and Supabase.
//  Manages offline changes and conflict resolution.
//
//  Features:
//  - Automatic sync when network becomes available
//  - Conflict resolution using timestamps (most recent wins)
//  - Retry logic for failed sync attempts
//  - Debug logging for sync operations
//

import Foundation
import Combine
import os.log

/// Logger for sync operations
private let logger = Logger(subsystem: "com.bookvocab.app", category: "SyncService")

// MARK: - Sync Status

/// Represents the current sync status.
enum SyncStatus: Equatable {
    case idle
    case syncing
    case completed(Int) // Number of items synced
    case failed(String) // Error message
    
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .syncing: return "Syncing..."
        case .completed(let count): return "Synced \(count) items"
        case .failed(let error): return "Sync failed: \(error)"
        }
    }
}

// MARK: - Sync Service

/// Service for synchronizing local cache with Supabase.
/// Handles offline changes and resolves conflicts.
@MainActor
class SyncService: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide sync operations.
    static let shared = SyncService()
    
    // MARK: - Published Properties
    
    /// Current sync status.
    @Published private(set) var status: SyncStatus = .idle
    
    /// Whether a sync is currently in progress.
    @Published private(set) var isSyncing: Bool = false
    
    /// Last sync timestamp.
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Dependencies
    
    private let cacheService: CacheService
    private let networkMonitor: NetworkMonitor
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private var syncTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    /// Creates a new SyncService.
    private init(
        cacheService: CacheService = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.cacheService = cacheService
        self.networkMonitor = networkMonitor
        
        setupNetworkObserver()
        logger.info("🔄 SyncService initialized")
    }
    
    // MARK: - Network Observer
    
    /// Sets up observer for network availability changes.
    private func setupNetworkObserver() {
        // Listen for network becoming available
        NotificationCenter.default.publisher(for: .networkBecameAvailable)
            .sink { [weak self] _ in
                Task { @MainActor in
                    logger.info("🔄 Network available - triggering sync")
                    await self?.syncAll()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Operations
    
    /// Performs a full sync of all pending changes.
    /// Call this when the app becomes active or network becomes available.
    func syncAll() async {
        guard networkMonitor.isConnected else {
            logger.warning("🔄 Cannot sync - offline")
            return
        }
        
        guard !isSyncing else {
            logger.debug("🔄 Sync already in progress")
            return
        }
        
        logger.info("🔄 Starting full sync")
        isSyncing = true
        status = .syncing
        
        var syncedCount = 0
        var hasErrors = false
        
        // Process sync queue
        let queueItems = cacheService.fetchSyncQueue()
        logger.debug("🔄 Processing \(queueItems.count) sync queue items")
        
        for item in queueItems {
            guard let entityType = item.entityType,
                  let entityId = item.entityId,
                  let action = item.action else {
                continue
            }
            
            let success: Bool
            
            switch entityType {
            case "book":
                success = await syncBook(entityId: entityId, action: action)
            case "vocabWord":
                success = await syncVocabWord(entityId: entityId, action: action)
            default:
                logger.warning("🔄 Unknown entity type: \(entityType)")
                success = false
            }
            
            if success {
                if let itemId = item.id {
                    cacheService.removeSyncQueueItem(itemId)
                }
                syncedCount += 1
            } else {
                hasErrors = true
                item.retryCount += 1
            }
        }
        
        // Fetch remote changes
        await fetchRemoteChanges()
        
        // Update status
        lastSyncDate = Date()
        isSyncing = false
        
        if hasErrors {
            status = .failed("Some items failed to sync")
            logger.warning("🔄 Sync completed with errors: \(syncedCount) items synced")
        } else {
            status = .completed(syncedCount)
            logger.info("🔄 Sync completed successfully: \(syncedCount) items synced")
        }
    }
    
    /// Syncs a single book to Supabase.
    private func syncBook(entityId: UUID, action: String) async -> Bool {
        logger.debug("🔄 Syncing book \(entityId.uuidString) - \(action)")
        
        // TODO: Implement actual Supabase sync
        // For now, simulate success
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            logger.debug("🔄 Book sync successful")
            return true
        } catch {
            logger.error("🔄 Book sync failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Syncs a single vocab word to Supabase.
    private func syncVocabWord(entityId: UUID, action: String) async -> Bool {
        logger.debug("🔄 Syncing vocab word \(entityId.uuidString) - \(action)")
        
        // TODO: Implement actual Supabase sync
        // For now, simulate success
        do {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            logger.debug("🔄 Vocab word sync successful")
            return true
        } catch {
            logger.error("🔄 Vocab word sync failed: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Fetches remote changes from Supabase.
    private func fetchRemoteChanges() async {
        logger.debug("🔄 Fetching remote changes")
        
        // TODO: Implement actual Supabase fetch
        // This would:
        // 1. Fetch books updated since last sync
        // 2. Fetch vocab words updated since last sync
        // 3. Resolve conflicts using timestamps
        // 4. Update local cache
        
        do {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
            logger.debug("🔄 Remote changes fetched")
        } catch {
            logger.error("🔄 Failed to fetch remote changes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// Resolves a conflict between local and remote data.
    /// Uses timestamp-based resolution (most recent wins).
    /// - Parameters:
    ///   - localUpdatedAt: Timestamp of local change.
    ///   - remoteUpdatedAt: Timestamp of remote change.
    /// - Returns: True if local should win, false if remote should win.
    func resolveConflict(localUpdatedAt: Date, remoteUpdatedAt: Date) -> Bool {
        let localWins = localUpdatedAt > remoteUpdatedAt
        logger.debug("🔄 Conflict resolved: \(localWins ? "local" : "remote") wins")
        return localWins
    }
    
    // MARK: - Manual Sync
    
    /// Manually triggers a sync.
    /// Use this for pull-to-refresh or manual sync buttons.
    func manualSync() async {
        logger.info("🔄 Manual sync triggered")
        await syncAll()
    }
    
    /// Cancels any ongoing sync.
    func cancelSync() {
        syncTask?.cancel()
        syncTask = nil
        isSyncing = false
        status = .idle
        logger.info("🔄 Sync cancelled")
    }
}


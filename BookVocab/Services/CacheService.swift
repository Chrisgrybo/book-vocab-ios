//
//  CacheService.swift
//  BookVocab
//
//  Provides caching operations using Core Data for offline support.
//  Handles reading/writing books and vocab words to local storage.
//
//  Features:
//  - CRUD operations for cached books and vocab words
//  - Sync queue management for offline changes
//  - Timestamp-based conflict resolution
//  - Debug logging for all cache operations
//

import Foundation
import CoreData
import os.log

/// Logger for cache operations
private let logger = Logger(subsystem: "com.bookvocab.app", category: "CacheService")

// MARK: - Cache Service

/// Service for managing local cache using Core Data.
/// Provides offline storage and sync queue functionality.
@MainActor
class CacheService: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide caching.
    static let shared = CacheService()
    
    // MARK: - Properties
    
    /// The persistence controller for Core Data operations.
    private let persistence: PersistenceController
    
    /// The view context for UI operations.
    private var viewContext: NSManagedObjectContext {
        persistence.viewContext
    }
    
    // MARK: - Published Properties
    
    /// Number of items in the sync queue.
    @Published private(set) var pendingSyncCount: Int = 0
    
    // MARK: - Initialization
    
    /// Creates a new CacheService with the shared persistence controller.
    private init(persistence: PersistenceController = .shared) {
        self.persistence = persistence
        updatePendingSyncCount()
        logger.info("💾 CacheService initialized")
    }
    
    // MARK: - Book Operations
    
    /// Fetches all cached books for a user.
    /// - Parameter userId: The user's ID.
    /// - Returns: Array of Book models from cache.
    func fetchBooks(for userId: UUID) -> [Book] {
        logger.debug("💾 Fetching cached books for user \(userId.uuidString)")
        
        let request = NSFetchRequest<CachedBook>(entityName: "CachedBook")
        request.predicate = NSPredicate(format: "userId == %@ AND markedForDeletion == NO", userId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedBook.createdAt, ascending: false)]
        
        do {
            let cached = try viewContext.fetch(request)
            let books = cached.map { $0.toBook() }
            logger.debug("💾 Found \(books.count) cached books")
            return books
        } catch {
            logger.error("❌ Failed to fetch cached books: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Saves a book to the cache.
    /// - Parameters:
    ///   - book: The book to cache.
    ///   - needsSync: Whether this change needs to be synced to Supabase.
    func saveBook(_ book: Book, needsSync: Bool = true) {
        logger.debug("💾 Saving book to cache: '\(book.title)'")
        
        // Check if book already exists
        let request = NSFetchRequest<CachedBook>(entityName: "CachedBook")
        request.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            
            let cached: CachedBook
            if let existing = results.first {
                cached = existing
                logger.debug("💾 Updating existing cached book")
            } else {
                cached = CachedBook(context: viewContext)
                logger.debug("💾 Creating new cached book")
            }
            
            cached.update(from: book)
            cached.needsSync = needsSync
            
            persistence.save()
            
            if needsSync {
                addToSyncQueue(entityType: "book", entityId: book.id, action: results.isEmpty ? "create" : "update")
            }
            
            logger.info("💾 Book cached successfully: '\(book.title)'")
        } catch {
            logger.error("❌ Failed to save book to cache: \(error.localizedDescription)")
        }
    }
    
    /// Saves multiple books to the cache.
    /// - Parameters:
    ///   - books: Array of books to cache.
    ///   - needsSync: Whether these changes need to be synced.
    func saveBooks(_ books: [Book], needsSync: Bool = false) {
        logger.debug("💾 Saving \(books.count) books to cache")
        
        for book in books {
            saveBook(book, needsSync: needsSync)
        }
    }
    
    /// Deletes a book from the cache.
    /// - Parameters:
    ///   - bookId: The book's ID.
    ///   - hardDelete: If true, removes from Core Data. If false, marks as deleted for sync.
    func deleteBook(_ bookId: UUID, hardDelete: Bool = false) {
        logger.debug("💾 Deleting book from cache: \(bookId.uuidString)")
        
        let request = NSFetchRequest<CachedBook>(entityName: "CachedBook")
        request.predicate = NSPredicate(format: "id == %@", bookId as CVarArg)
        
        do {
            if let cached = try viewContext.fetch(request).first {
                if hardDelete {
                    viewContext.delete(cached)
                } else {
                    cached.markedForDeletion = true
                    cached.needsSync = true
                    addToSyncQueue(entityType: "book", entityId: bookId, action: "delete")
                }
                persistence.save()
                logger.info("💾 Book deleted from cache")
            }
        } catch {
            logger.error("❌ Failed to delete book from cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - VocabWord Operations
    
    /// Fetches all cached vocab words.
    /// - Returns: Array of VocabWord models from cache.
    func fetchAllVocabWords() -> [VocabWord] {
        logger.debug("💾 Fetching all cached vocab words")
        
        let request = NSFetchRequest<CachedVocabWord>(entityName: "CachedVocabWord")
        request.predicate = NSPredicate(format: "markedForDeletion == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedVocabWord.createdAt, ascending: false)]
        
        do {
            let cached = try viewContext.fetch(request)
            let words = cached.map { $0.toVocabWord() }
            logger.debug("💾 Found \(words.count) cached vocab words")
            return words
        } catch {
            logger.error("❌ Failed to fetch cached vocab words: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Fetches cached vocab words for a specific book.
    /// - Parameter bookId: The book's ID.
    /// - Returns: Array of VocabWord models from cache.
    func fetchVocabWords(for bookId: UUID) -> [VocabWord] {
        logger.debug("💾 Fetching cached vocab words for book \(bookId.uuidString)")
        
        let request = NSFetchRequest<CachedVocabWord>(entityName: "CachedVocabWord")
        request.predicate = NSPredicate(format: "bookId == %@ AND markedForDeletion == NO", bookId as CVarArg)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CachedVocabWord.createdAt, ascending: false)]
        
        do {
            let cached = try viewContext.fetch(request)
            let words = cached.map { $0.toVocabWord() }
            logger.debug("💾 Found \(words.count) cached vocab words for book")
            return words
        } catch {
            logger.error("❌ Failed to fetch cached vocab words: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Saves a vocab word to the cache.
    /// - Parameters:
    ///   - word: The vocab word to cache.
    ///   - needsSync: Whether this change needs to be synced to Supabase.
    func saveVocabWord(_ word: VocabWord, needsSync: Bool = true) {
        logger.debug("💾 Saving vocab word to cache: '\(word.word)'")
        
        let request = NSFetchRequest<CachedVocabWord>(entityName: "CachedVocabWord")
        request.predicate = NSPredicate(format: "id == %@", word.id as CVarArg)
        
        do {
            let results = try viewContext.fetch(request)
            
            let cached: CachedVocabWord
            if let existing = results.first {
                cached = existing
                logger.debug("💾 Updating existing cached vocab word")
            } else {
                cached = CachedVocabWord(context: viewContext)
                logger.debug("💾 Creating new cached vocab word")
            }
            
            cached.update(from: word)
            cached.needsSync = needsSync
            
            persistence.save()
            
            if needsSync {
                addToSyncQueue(entityType: "vocabWord", entityId: word.id, action: results.isEmpty ? "create" : "update")
            }
            
            logger.info("💾 Vocab word cached successfully: '\(word.word)'")
        } catch {
            logger.error("❌ Failed to save vocab word to cache: \(error.localizedDescription)")
        }
    }
    
    /// Saves multiple vocab words to the cache.
    /// - Parameters:
    ///   - words: Array of vocab words to cache.
    ///   - needsSync: Whether these changes need to be synced.
    func saveVocabWords(_ words: [VocabWord], needsSync: Bool = false) {
        logger.debug("💾 Saving \(words.count) vocab words to cache")
        
        for word in words {
            saveVocabWord(word, needsSync: needsSync)
        }
    }
    
    /// Updates the mastered status of a vocab word.
    /// - Parameters:
    ///   - wordId: The word's ID.
    ///   - mastered: The new mastered status.
    func updateMasteredStatus(_ wordId: UUID, mastered: Bool) {
        logger.debug("💾 Updating mastered status for word \(wordId.uuidString) to \(mastered)")
        
        let request = NSFetchRequest<CachedVocabWord>(entityName: "CachedVocabWord")
        request.predicate = NSPredicate(format: "id == %@", wordId as CVarArg)
        
        do {
            if let cached = try viewContext.fetch(request).first {
                cached.mastered = mastered
                cached.updatedAt = Date()
                cached.needsSync = true
                
                persistence.save()
                addToSyncQueue(entityType: "vocabWord", entityId: wordId, action: "update")
                
                logger.info("💾 Mastered status updated in cache")
            }
        } catch {
            logger.error("❌ Failed to update mastered status: \(error.localizedDescription)")
        }
    }
    
    /// Deletes a vocab word from the cache.
    /// - Parameters:
    ///   - wordId: The word's ID.
    ///   - hardDelete: If true, removes from Core Data. If false, marks as deleted for sync.
    func deleteVocabWord(_ wordId: UUID, hardDelete: Bool = false) {
        logger.debug("💾 Deleting vocab word from cache: \(wordId.uuidString)")
        
        let request = NSFetchRequest<CachedVocabWord>(entityName: "CachedVocabWord")
        request.predicate = NSPredicate(format: "id == %@", wordId as CVarArg)
        
        do {
            if let cached = try viewContext.fetch(request).first {
                if hardDelete {
                    viewContext.delete(cached)
                } else {
                    cached.markedForDeletion = true
                    cached.needsSync = true
                    addToSyncQueue(entityType: "vocabWord", entityId: wordId, action: "delete")
                }
                persistence.save()
                logger.info("💾 Vocab word deleted from cache")
            }
        } catch {
            logger.error("❌ Failed to delete vocab word from cache: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sync Queue Operations
    
    /// Adds an item to the sync queue.
    private func addToSyncQueue(entityType: String, entityId: UUID, action: String, payload: String? = nil) {
        logger.debug("📤 Adding to sync queue: \(entityType) \(action)")
        
        let item = SyncQueueItem(context: viewContext)
        item.id = UUID()
        item.entityType = entityType
        item.entityId = entityId
        item.action = action
        item.payload = payload
        item.createdAt = Date()
        item.retryCount = 0
        
        persistence.save()
        updatePendingSyncCount()
    }
    
    /// Fetches all pending sync queue items.
    /// - Returns: Array of SyncQueueItem entities.
    func fetchSyncQueue() -> [SyncQueueItem] {
        logger.debug("📤 Fetching sync queue")
        
        let request = NSFetchRequest<SyncQueueItem>(entityName: "SyncQueueItem")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SyncQueueItem.createdAt, ascending: true)]
        
        do {
            let items = try viewContext.fetch(request)
            logger.debug("📤 Found \(items.count) items in sync queue")
            return items
        } catch {
            logger.error("❌ Failed to fetch sync queue: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Removes an item from the sync queue.
    /// - Parameter itemId: The sync queue item's ID.
    func removeSyncQueueItem(_ itemId: UUID) {
        let request = NSFetchRequest<SyncQueueItem>(entityName: "SyncQueueItem")
        request.predicate = NSPredicate(format: "id == %@", itemId as CVarArg)
        
        do {
            if let item = try viewContext.fetch(request).first {
                viewContext.delete(item)
                persistence.save()
                updatePendingSyncCount()
                logger.debug("📤 Removed item from sync queue")
            }
        } catch {
            logger.error("❌ Failed to remove sync queue item: \(error.localizedDescription)")
        }
    }
    
    /// Clears all items from the sync queue.
    func clearSyncQueue() {
        logger.debug("📤 Clearing sync queue")
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "SyncQueueItem")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try viewContext.execute(deleteRequest)
            persistence.save()
            updatePendingSyncCount()
            logger.info("📤 Sync queue cleared")
        } catch {
            logger.error("❌ Failed to clear sync queue: \(error.localizedDescription)")
        }
    }
    
    /// Updates the pending sync count.
    private func updatePendingSyncCount() {
        let request = NSFetchRequest<SyncQueueItem>(entityName: "SyncQueueItem")
        
        do {
            pendingSyncCount = try viewContext.count(for: request)
        } catch {
            pendingSyncCount = 0
        }
    }
    
    // MARK: - Cache Management
    
    /// Clears all cached data.
    /// Use with caution - this removes all offline data.
    func clearAllCache() {
        logger.warning("💾 Clearing all cached data")
        
        let entities = ["CachedBook", "CachedVocabWord", "SyncQueueItem"]
        
        for entity in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try viewContext.execute(deleteRequest)
            } catch {
                logger.error("❌ Failed to clear \(entity): \(error.localizedDescription)")
            }
        }
        
        persistence.save()
        updatePendingSyncCount()
        
        logger.info("💾 All cache cleared")
    }
    
    /// Gets the cache size in bytes.
    /// - Returns: Approximate cache size in bytes.
    func getCacheSize() -> Int64 {
        guard let storeURL = persistence.container.persistentStoreCoordinator.persistentStores.first?.url else {
            return 0
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            logger.error("❌ Failed to get cache size: \(error.localizedDescription)")
            return 0
        }
    }
}


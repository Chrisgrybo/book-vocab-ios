//
//  PersistenceController.swift
//  BookVocab
//
//  Core Data stack for offline caching.
//  Provides local storage for books and vocabulary words.
//
//  Features:
//  - Programmatically defined Core Data model (no .xcdatamodeld file needed)
//  - Automatic schema migration
//  - Background context for async operations
//  - Preview support for SwiftUI previews
//

import CoreData
import os.log

/// Logger for Core Data operations
private let logger = Logger(subsystem: "com.bookvocab.app", category: "PersistenceController")

// MARK: - Persistence Controller

/// Manages the Core Data stack for offline caching.
/// Uses a programmatically defined model for flexibility.
class PersistenceController {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide use.
    static let shared = PersistenceController()
    
    /// Preview instance with in-memory store for SwiftUI previews.
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        
        // Add sample data for previews
        let viewContext = controller.container.viewContext
        
        // Create sample cached books
        for i in 0..<5 {
            let book = CachedBook(context: viewContext)
            book.id = UUID()
            book.userId = UUID()
            book.title = "Sample Book \(i + 1)"
            book.author = "Author \(i + 1)"
            book.coverImageUrl = nil
            book.createdAt = Date()
            book.updatedAt = Date()
            book.needsSync = false
        }
        
        // Create sample cached vocab words
        for i in 0..<10 {
            let word = CachedVocabWord(context: viewContext)
            word.id = UUID()
            word.bookId = UUID()
            word.word = "Word \(i + 1)"
            word.definition = "Definition for word \(i + 1)"
            word.synonyms = "synonym1, synonym2"
            word.antonyms = "antonym1, antonym2"
            word.exampleSentence = "This is an example sentence."
            word.mastered = i % 3 == 0
            word.createdAt = Date()
            word.updatedAt = Date()
            word.needsSync = false
        }
        
        do {
            try viewContext.save()
        } catch {
            logger.error("❌ Preview data save failed: \(error.localizedDescription)")
        }
        
        return controller
    }()
    
    // MARK: - Properties
    
    /// The persistent container holding the Core Data stack.
    let container: NSPersistentContainer
    
    /// Main view context for UI operations.
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }
    
    // MARK: - Initialization
    
    /// Creates a new PersistenceController.
    /// - Parameter inMemory: If true, uses an in-memory store (for previews/testing).
    init(inMemory: Bool = false) {
        // Create the managed object model programmatically
        let model = Self.createManagedObjectModel()
        
        container = NSPersistentContainer(name: "BookVocabCache", managedObjectModel: model)
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                logger.error("❌ Core Data failed to load: \(error.localizedDescription)")
                // In production, handle this gracefully
                fatalError("Core Data store failed to load: \(error)")
            }
            
            logger.info("✅ Core Data store loaded: \(description.url?.absoluteString ?? "unknown")")
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Model Definition
    
    /// Creates the managed object model programmatically.
    /// This avoids needing a .xcdatamodeld file.
    private static func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        // Define CachedBook entity
        let bookEntity = NSEntityDescription()
        bookEntity.name = "CachedBook"
        bookEntity.managedObjectClassName = "CachedBook"
        
        let bookAttributes: [(String, NSAttributeType, Bool)] = [
            ("id", .UUIDAttributeType, false),
            ("userId", .UUIDAttributeType, false),
            ("title", .stringAttributeType, false),
            ("author", .stringAttributeType, false),
            ("coverImageUrl", .stringAttributeType, true),
            ("bookDescription", .stringAttributeType, true),
            ("isbn", .stringAttributeType, true),
            ("createdAt", .dateAttributeType, false),
            ("updatedAt", .dateAttributeType, false),
            ("needsSync", .booleanAttributeType, false),
            ("markedForDeletion", .booleanAttributeType, false)
        ]
        
        bookEntity.properties = bookAttributes.map { name, type, optional in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            if name == "needsSync" || name == "markedForDeletion" {
                attr.defaultValue = false
            }
            return attr
        }
        
        // Define CachedVocabWord entity
        let wordEntity = NSEntityDescription()
        wordEntity.name = "CachedVocabWord"
        wordEntity.managedObjectClassName = "CachedVocabWord"
        
        let wordAttributes: [(String, NSAttributeType, Bool)] = [
            ("id", .UUIDAttributeType, false),
            ("bookId", .UUIDAttributeType, false),
            ("word", .stringAttributeType, false),
            ("definition", .stringAttributeType, false),
            ("synonyms", .stringAttributeType, true),
            ("antonyms", .stringAttributeType, true),
            ("exampleSentence", .stringAttributeType, true),
            ("mastered", .booleanAttributeType, false),
            ("createdAt", .dateAttributeType, false),
            ("updatedAt", .dateAttributeType, false),
            ("needsSync", .booleanAttributeType, false),
            ("markedForDeletion", .booleanAttributeType, false)
        ]
        
        wordEntity.properties = wordAttributes.map { name, type, optional in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            if name == "mastered" || name == "needsSync" || name == "markedForDeletion" {
                attr.defaultValue = false
            }
            return attr
        }
        
        // Define SyncQueue entity for pending changes
        let syncEntity = NSEntityDescription()
        syncEntity.name = "SyncQueueItem"
        syncEntity.managedObjectClassName = "SyncQueueItem"
        
        let syncAttributes: [(String, NSAttributeType, Bool)] = [
            ("id", .UUIDAttributeType, false),
            ("entityType", .stringAttributeType, false), // "book" or "vocabWord"
            ("entityId", .UUIDAttributeType, false),
            ("action", .stringAttributeType, false), // "create", "update", "delete"
            ("payload", .stringAttributeType, true), // JSON string of changes
            ("createdAt", .dateAttributeType, false),
            ("retryCount", .integer16AttributeType, false)
        ]
        
        syncEntity.properties = syncAttributes.map { name, type, optional in
            let attr = NSAttributeDescription()
            attr.name = name
            attr.attributeType = type
            attr.isOptional = optional
            if name == "retryCount" {
                attr.defaultValue = 0
            }
            return attr
        }
        
        model.entities = [bookEntity, wordEntity, syncEntity]
        
        return model
    }
    
    // MARK: - Context Operations
    
    /// Creates a new background context for async operations.
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    /// Saves the view context if there are changes.
    func save() {
        let context = viewContext
        
        guard context.hasChanges else {
            logger.debug("💾 No changes to save")
            return
        }
        
        do {
            try context.save()
            logger.debug("💾 Context saved successfully")
        } catch {
            logger.error("❌ Failed to save context: \(error.localizedDescription)")
        }
    }
    
    /// Saves a background context.
    func save(context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        
        do {
            try context.save()
            logger.debug("💾 Background context saved")
        } catch {
            logger.error("❌ Failed to save background context: \(error.localizedDescription)")
        }
    }
}

// MARK: - CachedBook Entity

/// Core Data entity for cached books.
@objc(CachedBook)
public class CachedBook: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var userId: UUID?
    @NSManaged public var title: String?
    @NSManaged public var author: String?
    @NSManaged public var coverImageUrl: String?
    @NSManaged public var bookDescription: String?
    @NSManaged public var isbn: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var markedForDeletion: Bool
    
    /// Converts to the app's Book model.
    func toBook() -> Book {
        Book(
            id: id ?? UUID(),
            userId: userId ?? UUID(),
            title: title ?? "",
            author: author ?? "",
            coverImageUrl: coverImageUrl,
            createdAt: createdAt ?? Date()
        )
    }
    
    /// Updates from a Book model.
    func update(from book: Book) {
        self.id = book.id
        self.userId = book.userId
        self.title = book.title
        self.author = book.author
        self.coverImageUrl = book.coverImageUrl
        self.createdAt = book.createdAt
        self.updatedAt = Date()
    }
}

// MARK: - CachedVocabWord Entity

/// Core Data entity for cached vocabulary words.
@objc(CachedVocabWord)
public class CachedVocabWord: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var bookId: UUID?
    @NSManaged public var word: String?
    @NSManaged public var definition: String?
    @NSManaged public var synonyms: String?
    @NSManaged public var antonyms: String?
    @NSManaged public var exampleSentence: String?
    @NSManaged public var mastered: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var needsSync: Bool
    @NSManaged public var markedForDeletion: Bool
    
    /// Converts to the app's VocabWord model.
    func toVocabWord() -> VocabWord {
        VocabWord(
            id: id ?? UUID(),
            bookId: bookId ?? UUID(),
            word: word ?? "",
            definition: definition ?? "",
            synonyms: synonyms?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? [],
            antonyms: antonyms?.components(separatedBy: ", ").filter { !$0.isEmpty } ?? [],
            exampleSentence: exampleSentence ?? "",
            mastered: mastered,
            createdAt: createdAt ?? Date()
        )
    }
    
    /// Updates from a VocabWord model.
    func update(from vocabWord: VocabWord) {
        self.id = vocabWord.id
        self.bookId = vocabWord.bookId
        self.word = vocabWord.word
        self.definition = vocabWord.definition
        self.synonyms = vocabWord.synonyms.joined(separator: ", ")
        self.antonyms = vocabWord.antonyms.joined(separator: ", ")
        self.exampleSentence = vocabWord.exampleSentence
        self.mastered = vocabWord.mastered
        self.createdAt = vocabWord.createdAt
        self.updatedAt = Date()
    }
}

// MARK: - SyncQueueItem Entity

/// Core Data entity for sync queue items.
@objc(SyncQueueItem)
public class SyncQueueItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var entityType: String?
    @NSManaged public var entityId: UUID?
    @NSManaged public var action: String?
    @NSManaged public var payload: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var retryCount: Int16
}


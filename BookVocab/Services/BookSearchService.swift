//
//  BookSearchService.swift
//  BookVocab
//
//  Service layer for book search API integration.
//  Fetches book information and cover images from Google Books API.
//
//  API Documentation: https://developers.google.com/books/docs/v1/using
//
//  DEBUG LOGGING: This service includes detailed logging for cover image
//  fetching to help diagnose issues with book covers not displaying.
//

import Foundation
import os.log

// MARK: - Logger

/// Logger for BookSearchService debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "BookSearchService")

// MARK: - Google Books API Response Models

/// Root response from Google Books API.
struct GoogleBooksResponse: Codable {
    let totalItems: Int
    let items: [GoogleBookItem]?
}

/// A single book item from Google Books API.
struct GoogleBookItem: Codable {
    let id: String
    let volumeInfo: VolumeInfo
}

/// Volume information containing book details.
struct VolumeInfo: Codable {
    let title: String
    let authors: [String]?
    let description: String?
    let publishedDate: String?
    let imageLinks: ImageLinks?
    let industryIdentifiers: [IndustryIdentifier]?
}

/// Image URLs for book covers.
/// Note: Google Books API provides multiple image sizes.
/// - thumbnail: ~128px wide (preferred)
/// - smallThumbnail: ~80px wide (fallback)
struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
    
    /// Returns the best available cover URL, preferring thumbnail over smallThumbnail.
    /// Automatically converts HTTP to HTTPS for security.
    var bestAvailableUrl: String? {
        // Prefer thumbnail, fallback to smallThumbnail
        let rawUrl = thumbnail ?? smallThumbnail
        
        guard let url = rawUrl else {
            logger.debug("📚 ImageLinks: No cover URLs available")
            return nil
        }
        
        // Convert HTTP to HTTPS for security (Google Books sometimes returns http)
        let secureUrl = url.hasPrefix("http://") 
            ? url.replacingOccurrences(of: "http://", with: "https://")
            : url
        
        logger.debug("📚 ImageLinks: Best URL = \(secureUrl)")
        return secureUrl
    }
}

/// ISBN and other identifiers.
struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

// MARK: - App Models

/// Response model for book search results used by the app.
struct BookSearchResult: Identifiable, Codable {
    let id: String
    let title: String
    let author: String
    let coverImageUrl: String?
    let description: String?
    let publishedDate: String?
    let isbn: String?
}

// MARK: - Error Types

/// Custom errors for book search operations.
enum BookSearchError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid search query."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse book data."
        case .noResults:
            return "No books found matching your search."
        }
    }
}

// MARK: - Book Search Service

/// Service class for book search API operations.
/// Uses Google Books API to search for books and fetch cover images.
///
/// Usage:
/// ```swift
/// let results = try await BookSearchService.shared.searchBooks(query: "The Great Gatsby")
/// let coverUrl = try await BookSearchService.shared.fetchCoverImageUrl(for: "1984 Orwell")
/// ```
class BookSearchService {
    
    // MARK: - Singleton
    
    /// Shared instance of the Book Search service.
    static let shared = BookSearchService()
    
    // MARK: - Configuration
    
    /// Base URL for Google Books API.
    private let baseUrl = "https://www.googleapis.com/books/v1/volumes"
    
    /// URLSession for network requests.
    private let session: URLSession
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern.
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - API Methods
    
    /// Searches for books by title using Google Books API.
    ///
    /// This method:
    /// 1. URL-encodes the search query
    /// 2. Calls Google Books API with `intitle:` prefix for title search
    /// 3. Parses results into BookSearchResult array
    /// 4. Logs detailed debug info for cover image fetching
    ///
    /// - Parameter query: The search query (book title)
    /// - Returns: Array of BookSearchResult objects (up to 10 results)
    /// - Throws: BookSearchError if the search fails
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        // Clean and encode the query
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else {
            logger.warning("📚 Search: Empty query provided")
            throw BookSearchError.noResults
        }
        
        logger.info("📚 Search: Starting search for '\(cleanedQuery)'")
        
        // Build the search URL with intitle: prefix for better title matching
        // Also request only 10 results to keep response fast
        let searchQuery = "intitle:\(cleanedQuery)"
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)?q=\(encodedQuery)&maxResults=10") else {
            logger.error("📚 Search: Failed to build URL for query '\(cleanedQuery)'")
            throw BookSearchError.invalidURL
        }
        
        logger.debug("📚 Search: Request URL = \(url.absoluteString)")
        
        // Make the network request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            logger.error("📚 Search: Network error - \(error.localizedDescription)")
            throw BookSearchError.networkError(error)
        }
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse {
            logger.debug("📚 Search: HTTP status = \(httpResponse.statusCode)")
            if !(200...299).contains(httpResponse.statusCode) {
                logger.error("📚 Search: HTTP error \(httpResponse.statusCode)")
                throw BookSearchError.networkError(
                    NSError(domain: "HTTP", code: httpResponse.statusCode)
                )
            }
        }
        
        // DEBUG: Log raw JSON response (truncated for readability)
        if let jsonString = String(data: data, encoding: .utf8) {
            let truncated = String(jsonString.prefix(500))
            logger.debug("📚 Search: Raw response (first 500 chars) = \(truncated)")
        }
        
        // Decode the response
        let googleResponse: GoogleBooksResponse
        do {
            googleResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        } catch {
            logger.error("📚 Search: Decoding error - \(error.localizedDescription)")
            throw BookSearchError.decodingError(error)
        }
        
        logger.info("📚 Search: Found \(googleResponse.totalItems) total items")
        
        // Check if we have results
        guard let items = googleResponse.items, !items.isEmpty else {
            logger.warning("📚 Search: No results for '\(cleanedQuery)'")
            throw BookSearchError.noResults
        }
        
        logger.info("📚 Search: Processing \(items.count) items")
        
        // Transform to our app's BookSearchResult model
        return items.enumerated().map { index, item in
            // DEBUG: Log imageLinks for each result
            logger.debug("📚 Result[\(index)]: '\(item.volumeInfo.title)'")
            
            if let imageLinks = item.volumeInfo.imageLinks {
                logger.debug("  - thumbnail: \(imageLinks.thumbnail ?? "nil")")
                logger.debug("  - smallThumbnail: \(imageLinks.smallThumbnail ?? "nil")")
            } else {
                logger.debug("  - imageLinks: nil (no cover available)")
            }
            
            // Use the bestAvailableUrl helper for HTTPS-safe cover URL
            let coverUrl = item.volumeInfo.imageLinks?.bestAvailableUrl
            
            if let url = coverUrl {
                logger.info("📚 Result[\(index)]: Cover URL = \(url)")
            } else {
                logger.warning("📚 Result[\(index)]: No cover available for '\(item.volumeInfo.title)'")
            }
            
            // Get ISBN if available (prefer ISBN_13 over ISBN_10)
            let isbn = item.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
                ?? item.volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
            
            return BookSearchResult(
                id: item.id,
                title: item.volumeInfo.title,
                author: item.volumeInfo.authors?.joined(separator: ", ") ?? "Unknown Author",
                coverImageUrl: coverUrl,
                description: item.volumeInfo.description,
                publishedDate: item.volumeInfo.publishedDate,
                isbn: isbn
            )
        }
    }
    
    /// Fetches the cover image URL for a book by title.
    ///
    /// This is a convenience method that searches for the book and returns
    /// just the cover URL from the first result that has one.
    ///
    /// Fallback behavior:
    /// 1. Searches all results for the first one with a cover
    /// 2. Prefers thumbnail over smallThumbnail
    /// 3. Ensures HTTPS URLs
    ///
    /// - Parameter query: The book title to search for
    /// - Returns: URL string for the cover image, or nil if not found
    func fetchCoverImageUrl(for query: String) async -> String? {
        logger.info("📚 FetchCover: Looking for cover for '\(query)'")
        
        do {
            let results = try await searchBooks(query: query)
            
            // Find the first result that has a cover image
            if let resultWithCover = results.first(where: { $0.coverImageUrl != nil }) {
                logger.info("📚 FetchCover: Found cover for '\(query)' from '\(resultWithCover.title)'")
                logger.debug("📚 FetchCover: URL = \(resultWithCover.coverImageUrl ?? "nil")")
                return resultWithCover.coverImageUrl
            } else {
                // No results have covers - log this for debugging
                logger.warning("📚 FetchCover: No covers found in \(results.count) results for '\(query)'")
                return nil
            }
        } catch {
            // Log the error but return nil since cover is optional
            logger.error("📚 FetchCover: Search failed for '\(query)' - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Searches for a single book and returns the best match.
    ///
    /// - Parameter query: The book title to search for
    /// - Returns: The best matching BookSearchResult, or nil if not found
    func findBook(query: String) async -> BookSearchResult? {
        logger.info("📚 FindBook: Looking for '\(query)'")
        do {
            let results = try await searchBooks(query: query)
            if let first = results.first {
                logger.info("📚 FindBook: Found '\(first.title)' by \(first.author)")
                logger.debug("📚 FindBook: Cover URL = \(first.coverImageUrl ?? "nil")")
                return first
            }
            logger.warning("📚 FindBook: No results for '\(query)'")
            return nil
        } catch {
            logger.error("📚 FindBook: Error searching for '\(query)' - \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Converts a BookSearchResult to a Book model.
    ///
    /// - Parameters:
    ///   - result: The search result to convert
    ///   - userId: The user's ID to associate with the book
    /// - Returns: A Book model ready to be saved
    func convertToBook(_ result: BookSearchResult, userId: UUID) -> Book {
        logger.debug("📚 ConvertToBook: Creating Book from '\(result.title)'")
        logger.debug("📚 ConvertToBook: Cover URL = \(result.coverImageUrl ?? "nil")")
        
        return Book(
            userId: userId,
            title: result.title,
            author: result.author,
            coverImageUrl: result.coverImageUrl
        )
    }
    
    // MARK: - Test Methods
    
    /// Tests the book cover fetching with known books.
    /// Call this method to verify covers are being fetched correctly.
    ///
    /// Usage in debug: `await BookSearchService.shared.testCoverFetching()`
    func testCoverFetching() async {
        let testBooks = ["The Great Gatsby", "1984", "To Kill a Mockingbird", "Pride and Prejudice"]
        
        logger.info("📚 TEST: Starting cover fetch test for \(testBooks.count) books")
        
        for title in testBooks {
            logger.info("📚 TEST: Testing '\(title)'...")
            
            if let coverUrl = await fetchCoverImageUrl(for: title) {
                logger.info("✅ TEST: '\(title)' - Cover found: \(coverUrl)")
            } else {
                logger.error("❌ TEST: '\(title)' - No cover found!")
            }
        }
        
        logger.info("📚 TEST: Cover fetch test complete")
    }
}

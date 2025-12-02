//
//  BookSearchService.swift
//  BookVocab
//
//  Service layer for book search API integration.
//  Fetches book information and cover images from Google Books API.
//
//  API Documentation: https://developers.google.com/books/docs/v1/using
//

import Foundation

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
struct ImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
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
    ///
    /// - Parameter query: The search query (book title)
    /// - Returns: Array of BookSearchResult objects (up to 10 results)
    /// - Throws: BookSearchError if the search fails
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        // Clean and encode the query
        let cleanedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedQuery.isEmpty else {
            throw BookSearchError.noResults
        }
        
        // Build the search URL with intitle: prefix for better title matching
        // Also request only 10 results to keep response fast
        let searchQuery = "intitle:\(cleanedQuery)"
        guard let encodedQuery = searchQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseUrl)?q=\(encodedQuery)&maxResults=10") else {
            throw BookSearchError.invalidURL
        }
        
        // Make the network request
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw BookSearchError.networkError(error)
        }
        
        // Check HTTP status
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw BookSearchError.networkError(
                NSError(domain: "HTTP", code: httpResponse.statusCode)
            )
        }
        
        // Decode the response
        let googleResponse: GoogleBooksResponse
        do {
            googleResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
        } catch {
            throw BookSearchError.decodingError(error)
        }
        
        // Check if we have results
        guard let items = googleResponse.items, !items.isEmpty else {
            throw BookSearchError.noResults
        }
        
        // Transform to our app's BookSearchResult model
        return items.map { item in
            // Get the best available cover URL (prefer thumbnail over smallThumbnail)
            // Also convert http to https for security
            var coverUrl = item.volumeInfo.imageLinks?.thumbnail
                ?? item.volumeInfo.imageLinks?.smallThumbnail
            
            // Google Books sometimes returns http URLs, convert to https
            if let url = coverUrl, url.hasPrefix("http://") {
                coverUrl = url.replacingOccurrences(of: "http://", with: "https://")
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
    /// just the cover URL from the first result.
    ///
    /// - Parameter query: The book title to search for
    /// - Returns: URL string for the cover image, or nil if not found
    func fetchCoverImageUrl(for query: String) async -> String? {
        do {
            let results = try await searchBooks(query: query)
            // Return the first result that has a cover image
            return results.first(where: { $0.coverImageUrl != nil })?.coverImageUrl
        } catch {
            // Return nil if search fails - cover is optional
            return nil
        }
    }
    
    /// Searches for a single book and returns the best match.
    ///
    /// - Parameter query: The book title to search for
    /// - Returns: The best matching BookSearchResult, or nil if not found
    func findBook(query: String) async -> BookSearchResult? {
        do {
            let results = try await searchBooks(query: query)
            return results.first
        } catch {
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
        return Book(
            userId: userId,
            title: result.title,
            author: result.author,
            coverImageUrl: result.coverImageUrl
        )
    }
}

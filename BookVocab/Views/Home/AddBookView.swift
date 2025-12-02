//
//  AddBookView.swift
//  BookVocab
//
//  Screen for adding a new book to the collection.
//  Automatically fetches book covers from Google Books API.
//

import SwiftUI

/// View for adding a new book to the user's collection.
/// Supports search-based book addition with automatic cover fetching.
///
/// Features:
/// - Search Google Books API by title
/// - Auto-fetch and display book covers
/// - Manual entry mode for books not found in search
/// - Preview before saving
struct AddBookView: View {
    
    // MARK: - Environment
    
    /// Dismiss action for the sheet.
    @Environment(\.dismiss) private var dismiss
    
    /// Access to the shared user session view model.
    @EnvironmentObject var session: UserSessionViewModel
    
    /// Access to the shared books view model.
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    // MARK: - State
    
    /// Book title input.
    @State private var title: String = ""
    
    /// Book author input.
    @State private var author: String = ""
    
    /// Cover image URL (auto-fetched or manual).
    @State private var coverImageUrl: String = ""
    
    /// Search query for finding books.
    @State private var searchQuery: String = ""
    
    /// Search results from Google Books API.
    @State private var searchResults: [BookSearchResult] = []
    
    /// Toggle between manual and search modes.
    @State private var isSearchMode: Bool = true
    
    /// Loading state for search operations.
    @State private var isSearching: Bool = false
    
    /// Loading state for cover fetch in manual mode.
    @State private var isFetchingCover: Bool = false
    
    /// Error message for display.
    @State private var errorMessage: String?
    
    /// Show error alert.
    @State private var showingError: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates that required fields are filled.
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Mode picker (Search vs Manual)
                Section {
                    Picker("Entry Mode", selection: $isSearchMode) {
                        Text("Search").tag(true)
                        Text("Manual").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isSearchMode) { _, _ in
                        // Clear fields when switching modes
                        clearFields()
                    }
                }
                
                if isSearchMode {
                    // Search section
                    searchSection
                    
                    // Search results
                    if !searchResults.isEmpty {
                        searchResultsSection
                    }
                } else {
                    // Manual entry section
                    manualEntrySection
                }
                
                // Preview section (shows when we have title)
                if !title.isEmpty {
                    bookPreviewSection
                }
            }
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Save button
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveBook()
                    }
                    .disabled(!isFormValid || isSearching)
                }
            }
            .alert("Search Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Search input section.
    private var searchSection: some View {
        Section {
            HStack {
                TextField("Search by book title...", text: $searchQuery)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task { await performSearch() }
                    }
                
                Button {
                    Task { await performSearch() }
                } label: {
                    if isSearching {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSearching)
            }
        } header: {
            Text("Search Google Books")
        } footer: {
            Text("Search by title to find books and automatically fetch cover images.")
        }
    }
    
    /// Search results list.
    private var searchResultsSection: some View {
        Section("Search Results") {
            ForEach(searchResults) { result in
                Button {
                    selectSearchResult(result)
                } label: {
                    HStack(spacing: 12) {
                        // Cover thumbnail
                        if let coverUrl = result.coverImageUrl {
                            AsyncImage(url: URL(string: coverUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                smallCoverPlaceholder
                            }
                            .frame(width: 40, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            smallCoverPlaceholder
                                .frame(width: 40, height: 56)
                        }
                        
                        // Book info
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            
                            Text(result.author)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            
                            if let year = result.publishedDate?.prefix(4) {
                                Text(String(year))
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                        
                        Spacer()
                        
                        // Selection indicator
                        if result.title == title && result.author == author {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }
    
    /// Manual entry form fields.
    private var manualEntrySection: some View {
        Section {
            TextField("Book Title", text: $title)
                .onChange(of: title) { _, newValue in
                    // Auto-fetch cover when title changes (debounced)
                    if !newValue.isEmpty && coverImageUrl.isEmpty {
                        Task {
                            try? await Task.sleep(nanoseconds: 500_000_000)
                            if title == newValue && coverImageUrl.isEmpty {
                                await fetchCoverForManualEntry()
                            }
                        }
                    }
                }
            
            TextField("Author", text: $author)
            
            HStack {
                TextField("Cover Image URL (optional)", text: $coverImageUrl)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                if isFetchingCover {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        } header: {
            Text("Book Details")
        } footer: {
            Text("Enter details manually. Cover will be auto-fetched if found.")
        }
    }
    
    /// Preview of the book being added.
    private var bookPreviewSection: some View {
        Section("Preview") {
            HStack(spacing: 16) {
                // Cover preview
                if !coverImageUrl.isEmpty {
                    AsyncImage(url: URL(string: coverImageUrl)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            coverPlaceholder
                        case .empty:
                            ProgressView()
                        @unknown default:
                            coverPlaceholder
                        }
                    }
                    .frame(width: 70, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                } else {
                    coverPlaceholder
                        .frame(width: 70, height: 100)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(2)
                    
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if !coverImageUrl.isEmpty {
                        Label("Cover found", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Label("No cover", systemImage: "photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    /// Placeholder for book covers.
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(.blue.opacity(0.5))
            }
    }
    
    /// Small placeholder for search results.
    private var smallCoverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue.opacity(0.2))
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.caption)
                    .foregroundStyle(.blue.opacity(0.5))
            }
    }
    
    // MARK: - Actions
    
    /// Clears all form fields.
    private func clearFields() {
        title = ""
        author = ""
        coverImageUrl = ""
        searchQuery = ""
        searchResults = []
    }
    
    /// Performs book search using Google Books API.
    private func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            // Call Google Books API via our service
            searchResults = try await BookSearchService.shared.searchBooks(query: searchQuery)
            
            // Auto-select first result if we have results
            if let firstResult = searchResults.first {
                selectSearchResult(firstResult)
            }
        } catch let error as BookSearchError {
            errorMessage = error.localizedDescription
            showingError = true
            searchResults = []
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            showingError = true
            searchResults = []
        }
        
        isSearching = false
    }
    
    /// Selects a book from search results.
    private func selectSearchResult(_ result: BookSearchResult) {
        title = result.title
        author = result.author
        coverImageUrl = result.coverImageUrl ?? ""
    }
    
    /// Fetches cover image for manual entry mode.
    private func fetchCoverForManualEntry() async {
        guard !title.isEmpty else { return }
        
        isFetchingCover = true
        
        // Try to find a cover using the title
        let searchTerm = author.isEmpty ? title : "\(title) \(author)"
        if let coverUrl = await BookSearchService.shared.fetchCoverImageUrl(for: searchTerm) {
            // Only update if user hasn't entered a URL manually
            if coverImageUrl.isEmpty {
                coverImageUrl = coverUrl
            }
        }
        
        isFetchingCover = false
    }
    
    /// Saves the new book to the collection.
    private func saveBook() {
        // Get the user ID from the current Supabase session
        let userId = session.currentUser?.id ?? UUID()
        
        Task {
            await booksViewModel.addBook(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                author: author.trimmingCharacters(in: .whitespacesAndNewlines),
                coverImageUrl: coverImageUrl.isEmpty ? nil : coverImageUrl,
                userId: userId
            )
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddBookView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
}

//
//  AddBookView.swift
//  BookVocab
//
//  Screen for adding a new book to the collection.
//  Allows searching by title and auto-fetching cover images.
//

import SwiftUI

/// View for adding a new book to the user's collection.
/// Supports manual entry or search-based book addition.
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
    
    /// Search results from book search API.
    @State private var searchResults: [BookSearchResult] = []
    
    /// Toggle between manual and search modes.
    @State private var isSearchMode: Bool = true
    
    /// Loading state for search and save operations.
    @State private var isLoading: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates that required fields are filled.
    private var isFormValid: Bool {
        !title.isEmpty && !author.isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Mode picker
                Section {
                    Picker("Entry Mode", selection: $isSearchMode) {
                        Text("Search").tag(true)
                        Text("Manual").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                
                if isSearchMode {
                    // Search section
                    searchSection
                } else {
                    // Manual entry section
                    manualEntrySection
                }
                
                // Preview section
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
                    .disabled(!isFormValid || isLoading)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Search mode UI for finding books.
    private var searchSection: some View {
        Section("Search for a Book") {
            HStack {
                TextField("Search by title...", text: $searchQuery)
                    .textFieldStyle(.roundedBorder)
                
                Button {
                    Task {
                        await performSearch()
                    }
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .disabled(searchQuery.isEmpty || isLoading)
            }
            
            // Search results
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if !searchResults.isEmpty {
                ForEach(searchResults) { result in
                    Button {
                        selectSearchResult(result)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(result.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(result.author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    /// Manual entry UI for adding books.
    private var manualEntrySection: some View {
        Section("Book Details") {
            TextField("Title", text: $title)
            TextField("Author", text: $author)
            TextField("Cover Image URL (optional)", text: $coverImageUrl)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }
    
    /// Preview of the book being added.
    private var bookPreviewSection: some View {
        Section("Preview") {
            HStack(spacing: 16) {
                // Cover preview
                if !coverImageUrl.isEmpty {
                    AsyncImage(url: URL(string: coverImageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        coverPlaceholder
                    }
                    .frame(width: 60, height: 85)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    coverPlaceholder
                        .frame(width: 60, height: 85)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    /// Placeholder for book covers.
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.blue.opacity(0.2))
            .overlay {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.blue.opacity(0.5))
            }
    }
    
    // MARK: - Actions
    
    /// Performs book search using the search query.
    private func performSearch() async {
        isLoading = true
        
        // TODO: Implement actual book search
        // searchResults = try await BookSearchService.shared.searchBooks(query: searchQuery)
        
        // Placeholder: Simulate search delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Mock results for scaffolding
        searchResults = [
            BookSearchResult(
                id: UUID().uuidString,
                title: searchQuery,
                author: "Sample Author",
                coverImageUrl: nil,
                description: nil,
                publishedDate: nil,
                isbn: nil
            )
        ]
        
        isLoading = false
    }
    
    /// Selects a book from search results.
    private func selectSearchResult(_ result: BookSearchResult) {
        title = result.title
        author = result.author
        coverImageUrl = result.coverImageUrl ?? ""
    }
    
    /// Saves the new book to the collection.
    private func saveBook() {
        // Get the user ID from the current Supabase session
        guard let userId = session.currentUser?.id else {
            // Fallback for development/testing without auth
            let userId = UUID()
            Task {
                await booksViewModel.addBook(
                    title: title,
                    author: author,
                    coverImageUrl: coverImageUrl.isEmpty ? nil : coverImageUrl,
                    userId: userId
                )
                dismiss()
            }
            return
        }
        
        Task {
            await booksViewModel.addBook(
                title: title,
                author: author,
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

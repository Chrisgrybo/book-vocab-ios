//
//  AddBookView.swift
//  BookVocab
//
//  Premium sheet for adding a new book to the collection.
//  Clean design with smooth animations and intuitive flow.
//
//  Features:
//  - Search Google Books with live results
//  - Beautiful cover previews
//  - Manual entry option
//  - Smooth transitions
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "AddBookView")

struct AddBookView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: UserSessionViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    // MARK: - State
    
    @State private var title: String = ""
    @State private var author: String = ""
    @State private var coverImageUrl: String = ""
    @State private var searchQuery: String = ""
    @State private var searchResults: [BookSearchResult] = []
    @State private var isSearchMode: Bool = true
    @State private var isSearching: Bool = false
    @State private var isFetchingCover: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var selectedResultId: String?
    
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Mode toggle
                    modeToggle
                        .padding(.horizontal, AppSpacing.horizontalPadding)
                        .padding(.top, AppSpacing.md)
                    
                    if isSearchMode {
                        searchSection
                        
                        if !searchResults.isEmpty {
                            searchResultsSection
                        }
                    } else {
                        manualEntrySection
                    }
                    
                    // Preview
                    if !title.isEmpty {
                        previewSection
                    }
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveBook()
                    } label: {
                        Text("Add")
                            .fontWeight(.semibold)
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
    
    // MARK: - Mode Toggle
    
    private var modeToggle: some View {
        HStack(spacing: 0) {
            modeButton(title: "Search", icon: "magnifyingglass", isSelected: isSearchMode) {
                withAnimation(AppAnimation.spring) {
                    isSearchMode = true
                    clearFields()
                }
            }
            
            modeButton(title: "Manual", icon: "pencil", isSelected: !isSearchMode) {
                withAnimation(AppAnimation.spring) {
                    isSearchMode = false
                    clearFields()
                }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
    
    private func modeButton(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: icon)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(isSelected ? AppColors.cardBackground : Color.clear)
            .foregroundStyle(isSelected ? .primary : .secondary)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
            .shadow(color: isSelected ? .black.opacity(0.05) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Search Books")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.horizontalPadding)
            
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search by title or author...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            Task { await performSearch() }
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .padding(AppSpacing.sm)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                
                Button {
                    Task { await performSearch() }
                } label: {
                    Group {
                        if isSearching {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.right")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        if searchQuery.isEmpty {
                            Color.gray.opacity(0.3)
                        } else {
                            AppColors.primary
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .disabled(searchQuery.isEmpty || isSearching)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
        }
    }
    
    // MARK: - Search Results
    
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Results")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.horizontalPadding)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(searchResults) { result in
                        SearchResultCard(
                            result: result,
                            isSelected: selectedResultId == result.id
                        ) {
                            selectSearchResult(result)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.horizontalPadding)
            }
        }
    }
    
    // MARK: - Manual Entry
    
    private var manualEntrySection: some View {
        VStack(spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Book Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Enter book title", text: $title)
                    .textFieldStyle(.plain)
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                    .onChange(of: title) { _, newValue in
                        if !newValue.isEmpty && coverImageUrl.isEmpty {
                            Task {
                                try? await Task.sleep(nanoseconds: 500_000_000)
                                if title == newValue && coverImageUrl.isEmpty {
                                    await fetchCoverForManualEntry()
                                }
                            }
                        }
                    }
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Author")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Enter author name", text: $author)
                    .textFieldStyle(.plain)
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Cover URL")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text("(Optional)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    if isFetchingCover {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                
                TextField("Auto-fetched or enter URL", text: $coverImageUrl)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
            }
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Preview")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppSpacing.horizontalPadding)
            
            HStack(spacing: AppSpacing.md) {
                // Cover
                bookCoverPreview
                    .frame(width: 80, height: 115)
                
                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    if !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Status badges
                    HStack(spacing: AppSpacing.xs) {
                        if !coverImageUrl.isEmpty {
                            PillTag(text: "Cover found", color: AppColors.success, icon: "checkmark.circle.fill")
                        } else {
                            PillTag(text: "No cover", color: .gray, icon: "photo")
                        }
                    }
                }
                
                Spacer()
            }
            .padding(AppSpacing.md)
            .cardStyle()
            .padding(.horizontal, AppSpacing.horizontalPadding)
        }
    }
    
    private var bookCoverPreview: some View {
        Group {
            if !coverImageUrl.isEmpty, let url = URL(string: coverImageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        coverPlaceholder
                    case .empty:
                        coverPlaceholder
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    @unknown default:
                        coverPlaceholder
                    }
                }
            } else {
                coverPlaceholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
    }
    
    private var coverPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.tanDark, AppColors.tan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.closed.fill")
                .font(.title)
                .foregroundStyle(AppColors.primary.opacity(0.5))
        }
    }
    
    // MARK: - Actions
    
    private func clearFields() {
        title = ""
        author = ""
        coverImageUrl = ""
        searchQuery = ""
        searchResults = []
        selectedResultId = nil
    }
    
    private func performSearch() async {
        guard !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        errorMessage = nil
        
        do {
            searchResults = try await BookSearchService.shared.searchBooks(query: searchQuery)
            
            if let first = searchResults.first {
                selectSearchResult(first)
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
    
    private func selectSearchResult(_ result: BookSearchResult) {
        logger.info("📖 Selected: '\(result.title)' by \(result.author)")
        
        withAnimation(AppAnimation.spring) {
            selectedResultId = result.id
            title = result.title
            author = result.author
            coverImageUrl = result.coverImageUrl ?? ""
        }
    }
    
    private func fetchCoverForManualEntry() async {
        guard !title.isEmpty else { return }
        
        isFetchingCover = true
        let searchTerm = author.isEmpty ? title : "\(title) \(author)"
        
        if let coverUrl = await BookSearchService.shared.fetchCoverImageUrl(for: searchTerm) {
            if coverImageUrl.isEmpty {
                await MainActor.run {
                    withAnimation(AppAnimation.spring) {
                        coverImageUrl = coverUrl
                    }
                }
            }
        }
        
        isFetchingCover = false
    }
    
    private func saveBook() {
        let userId = session.currentUser?.id ?? UUID()
        
        logger.info("📖 Saving book: '\(title)' by \(author)")
        
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

// MARK: - Search Result Card

struct SearchResultCard: View {
    let result: BookSearchResult
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Cover
                Group {
                    if let coverUrl = result.coverImageUrl, let url = URL(string: coverUrl) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            placeholderCover
                        }
                    } else {
                        placeholderCover
                    }
                }
                .frame(width: 100, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.small, style: .continuous)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(result.author)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 100, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppAnimation.spring, value: isSelected)
    }
    
    private var placeholderCover: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.closed.fill")
                .foregroundStyle(.gray.opacity(0.5))
        }
    }
}

// MARK: - Preview

#Preview {
    AddBookView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
}

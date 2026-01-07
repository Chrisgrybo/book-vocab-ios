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
                HStack(spacing: AppSpacing.sm) {
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
                .padding(.vertical, 4) // Prevent highlight/shadow clipping
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
    
    /// Fixed dimensions for consistent card sizes
    private let coverWidth: CGFloat = 100
    private let coverHeight: CGFloat = 145
    
    /// Highlight border width
    private let highlightWidth: CGFloat = 2.5
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Cover container with padding for highlight visibility
                coverView
                    .padding(4) // Space for highlight border to render without clipping
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Text(result.author)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: coverWidth, alignment: .leading)
                .padding(.horizontal, 4) // Match horizontal padding of cover
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppAnimation.spring, value: isSelected)
    }
    
    /// The book cover with background, image, and selection highlight
    private var coverView: some View {
        ZStack {
            // Background fills entire frame
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(AppColors.tanDark.opacity(0.3))
            
            // Book cover image - contained within the background
            coverImage
        }
        .frame(width: coverWidth, height: coverHeight)
        // Apply corner radius via background, not clipShape
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(Color.clear)
        )
        // Clip the image content to rounded corners
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        // Selection highlight - renders OUTSIDE the clip
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .strokeBorder(
                    isSelected ? Color.blue.opacity(0.85) : Color.clear,
                    lineWidth: highlightWidth
                )
        )
        // Subtle shadow
        .shadow(
            color: isSelected ? Color.blue.opacity(0.25) : .black.opacity(0.1),
            radius: isSelected ? 6 : 3,
            x: 0,
            y: isSelected ? 3 : 2
        )
    }
    
    /// Async image loading with proper phase handling
    @ViewBuilder
    private var coverImage: some View {
        if let coverUrl = result.coverImageUrl, let url = URL(string: coverUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                case .failure:
                    placeholderCover
                case .empty:
                    placeholderCover
                        .overlay {
                            ProgressView()
                                .tint(AppColors.primary.opacity(0.5))
                        }
                @unknown default:
                    placeholderCover
                }
            }
        } else {
            placeholderCover
        }
    }
    
    private var placeholderCover: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.tanDark, AppColors.tan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 4) {
                Image(systemName: "book.closed.fill")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary.opacity(0.4))
                
                Text(result.title.prefix(10))
                    .font(.system(size: 8, weight: .medium))
                    .foregroundStyle(AppColors.primary.opacity(0.3))
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AddBookView()
        .environmentObject(UserSessionViewModel())
        .environmentObject(BooksViewModel())
}

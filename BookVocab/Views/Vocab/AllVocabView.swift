//
//  AllVocabView.swift
//  BookVocab
//
//  Premium view showing all vocabulary words across all books.
//  Clean design with stats header, filters, and word cards.
//
//  Features:
//  - Stats header with progress
//  - Filter and sort options
//  - Expandable word cards
//  - Smooth animations
//

import SwiftUI

struct AllVocabView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    // MARK: - State
    
    @State private var searchText: String = ""
    @State private var selectedFilter: WordFilter = .all
    @State private var sortOrder: SortOrder = .newest
    @State private var hasAppeared: Bool = false
    @State private var showingAddWord: Bool = false
    @State private var selectedWordForEdit: VocabWord?
    @State private var showDeleteError: Bool = false
    @State private var deleteErrorMessage: String = ""
    
    enum WordFilter: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case mastered = "Mastered"
    }
    
    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A-Z"
    }
    
    // MARK: - Computed Properties
    
    private var displayedWords: [VocabWord] {
        var words = vocabViewModel.allWords
        
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        switch selectedFilter {
        case .all: break
        case .learning: words = words.filter { !$0.mastered }
        case .mastered: words = words.filter { $0.mastered }
        }
        
        switch sortOrder {
        case .newest: words = words.sorted { $0.createdAt > $1.createdAt }
        case .oldest: words = words.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical: words = words.sorted { $0.word.lowercased() < $1.word.lowercased() }
        }
        
        return words
    }
    
    private var progress: Double {
        guard vocabViewModel.totalWordCount > 0 else { return 0 }
        return Double(vocabViewModel.masteredCount) / Double(vocabViewModel.totalWordCount)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if vocabViewModel.allWords.isEmpty {
                    ScrollView {
                        emptyStateView
                            .padding(.top, AppSpacing.xxxl)
                    }
                } else {
                    List {
                        // Stats header section
                        Section {
                            statsHeader
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Filters section
                        Section {
                            filterSection
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        
                        // Words section with swipe actions
                        Section {
                            wordsListContent
                        } header: {
                            HStack {
                                Text("Words")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                Text("\(displayedWords.count) words")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .textCase(nil)
                            .padding(.vertical, AppSpacing.sm)
                        }
                        .listRowInsets(EdgeInsets(top: 4, leading: AppSpacing.horizontalPadding, bottom: 4, trailing: AppSpacing.horizontalPadding))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("All Words")
            .searchable(text: $searchText, prompt: "Search words...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: AppSpacing.sm) {
                        // Add Word button
                        Button {
                            showingAddWord = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                        }
                        
                        // Sort menu
                        sortMenu
                    }
                }
            }
            .sheet(isPresented: $showingAddWord) {
                AddVocabView()
            }
            .sheet(item: $selectedWordForEdit) { word in
                EditWordView(word: word)
                    .environmentObject(vocabViewModel)
            }
            .alert("Delete Failed", isPresented: $showDeleteError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(deleteErrorMessage)
            }
            .refreshable {
                await vocabViewModel.fetchAllWords()
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeader: some View {
        HStack(spacing: AppSpacing.lg) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppColors.greenGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppAnimation.smooth, value: progress)
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                    Text("done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)
            
            // Stats
            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(vocabViewModel.totalWordCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 2) {
                    Text("\(vocabViewModel.masteredCount)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.success)
                    Text("Mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 40)
                
                VStack(spacing: 2) {
                    Text("\(vocabViewModel.learningWords.count)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.warning)
                    Text("Learning")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                ForEach(WordFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(AppAnimation.spring) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
        }
    }
    
    private func countForFilter(_ filter: WordFilter) -> Int {
        switch filter {
        case .all: return vocabViewModel.totalWordCount
        case .learning: return vocabViewModel.learningWords.count
        case .mastered: return vocabViewModel.masteredCount
        }
    }
    
    // MARK: - Words List Content (with swipe actions)
    
    @ViewBuilder
    private var wordsListContent: some View {
        if displayedWords.isEmpty {
            noResultsView
        } else {
            ForEach(Array(displayedWords.enumerated()), id: \.element.id) { index, word in
                // Word card with swipe actions
                AllWordsCardView(
                    word: word,
                    bookTitle: bookTitle(for: word),
                    onEdit: {
                        selectedWordForEdit = word
                    }
                )
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(
                    AppAnimation.spring.delay(Double(index) * 0.02),
                    value: hasAppeared
                )
                // Swipe LEFT to reveal Edit and Delete
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    // Delete button (red)
                    Button(role: .destructive) {
                        Task {
                            await deleteWord(word)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    // Edit button (blue)
                    Button {
                        selectedWordForEdit = word
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
                
                // Insert MREC ad every 5 words (as a separate row)
                if shouldShowAd(at: index) {
                    AdMRECView()
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }
        }
    }
    
    /// Determines if an ad should be shown after the given index.
    private func shouldShowAd(at index: Int) -> Bool {
        @AppStorage("isPremium") var isPremium: Bool = false
        guard !isPremium else { return false }
        guard displayedWords.count >= 5 else { return false }
        guard index < displayedWords.count - 1 else { return false }
        return (index + 1) % 5 == 0
    }
    
    private var noResultsView: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(.tertiary)
            
            Text("No words found")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxxl)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 140, height: 140)
                
                Image(systemName: "textformat.abc")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Words Yet")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add vocabulary words from your\nbooks or create global words.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddWord = true
            } label: {
                Label("Add Your First Word", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, AppSpacing.xxxl)
        }
        .padding(AppSpacing.xl)
    }
    
    // MARK: - Toolbar
    
    private var sortMenu: some View {
        Menu {
            Section("Sort by") {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .font(.title3)
        }
    }
    
    // MARK: - Helpers
    
    /// Returns the book title for a word, or "All Words" if the word is global (no book assigned).
    private func bookTitle(for word: VocabWord) -> String {
        guard let bookId = word.bookId else {
            return "All Words"
        }
        return booksViewModel.books.first { $0.id == bookId }?.title ?? "Unknown"
    }
    
    /// Deletes a word with animation and error handling.
    private func deleteWord(_ word: VocabWord) async {
        withAnimation(AppAnimation.spring) {
            Task {
                await vocabViewModel.deleteWord(word)
            }
        }
        
        // Check for errors
        if let error = vocabViewModel.errorMessage {
            deleteErrorMessage = error
            showDeleteError = true
        }
    }
}

// MARK: - All Words Card View

struct AllWordsCardView: View {
    let word: VocabWord
    let bookTitle: String
    var onEdit: (() -> Void)? = nil
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(alignment: .top, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(word.word)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if word.mastered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.success)
                        }
                    }
                    
                    HStack(spacing: AppSpacing.xxs) {
                        Image(systemName: bookTitle == "All Words" ? "tray.full" : "book.closed.fill")
                            .font(.caption2)
                        Text(bookTitle)
                            .font(.caption)
                    }
                    .foregroundStyle(.tertiary)
                    
                    Text(word.definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                Button {
                    Task {
                        await vocabViewModel.toggleMastered(word)
                    }
                } label: {
                    Image(systemName: word.mastered ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(word.mastered ? AppColors.success : Color.gray.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Divider()
                        .padding(.vertical, AppSpacing.sm)
                    
                    if !word.exampleSentence.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Example", systemImage: "text.quote")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("\"\(word.exampleSentence)\"")
                                .font(.subheadline)
                                .italic()
                        }
                    }
                    
                    if !word.synonyms.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Synonyms", systemImage: "equal.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            FlexibleView(data: word.synonyms, spacing: 6, alignment: .leading) { syn in
                                Text(syn)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if !word.antonyms.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Antonyms", systemImage: "arrow.left.arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            FlexibleView(data: word.antonyms, spacing: 6, alignment: .leading) { ant in
                                Text(ant)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Expand indicator
            HStack {
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            // Toggle expansion on tap
            withAnimation(AppAnimation.spring) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AllVocabView()
        .environmentObject(VocabViewModel())
        .environmentObject(BooksViewModel())
}

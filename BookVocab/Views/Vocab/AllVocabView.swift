//
//  AllVocabView.swift
//  BookVocab
//
//  Global view showing all vocabulary words across all books.
//  Provides filtering, searching, and management capabilities.
//

import SwiftUI

/// View displaying all vocabulary words from all books.
/// Supports searching, filtering by mastery status, and sorting.
struct AllVocabView: View {
    
    // MARK: - Environment
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Access to the shared books view model.
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    // MARK: - State
    
    /// Search text for filtering words.
    @State private var searchText: String = ""
    
    /// Current filter selection.
    @State private var selectedFilter: WordFilter = .all
    
    /// Current sort order.
    @State private var sortOrder: SortOrder = .newest
    
    // MARK: - Enums
    
    /// Filter options for the word list.
    enum WordFilter: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case mastered = "Mastered"
    }
    
    /// Sort options for the word list.
    enum SortOrder: String, CaseIterable {
        case newest = "Newest"
        case oldest = "Oldest"
        case alphabetical = "A-Z"
    }
    
    // MARK: - Computed Properties
    
    /// Words filtered and sorted based on current selections.
    private var displayedWords: [VocabWord] {
        var words = vocabViewModel.allWords
        
        // Apply search filter
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .learning:
            words = words.filter { !$0.mastered }
        case .mastered:
            words = words.filter { $0.mastered }
        }
        
        // Apply sort
        switch sortOrder {
        case .newest:
            words = words.sorted { $0.createdAt > $1.createdAt }
        case .oldest:
            words = words.sorted { $0.createdAt < $1.createdAt }
        case .alphabetical:
            words = words.sorted { $0.word.lowercased() < $1.word.lowercased() }
        }
        
        return words
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if vocabViewModel.allWords.isEmpty {
                    emptyStateView
                } else {
                    wordListView
                }
            }
            .navigationTitle("All Words")
            .searchable(text: $searchText, prompt: "Search words...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    filterMenu
                }
            }
            .refreshable {
                await vocabViewModel.fetchAllWords()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state when no words exist.
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Words Yet", systemImage: "textformat.abc")
        } description: {
            Text("Add vocabulary words from your books to see them here.")
        }
    }
    
    /// Main list of vocabulary words.
    private var wordListView: some View {
        List {
            // Stats header
            statsHeader
            
            // Filter pills
            filterPills
            
            // Word list
            Section {
                ForEach(displayedWords) { word in
                    AllVocabRowView(word: word, bookTitle: bookTitle(for: word))
                }
                .onDelete { offsets in
                    deleteWords(at: offsets)
                }
            } header: {
                Text("\(displayedWords.count) words")
            }
        }
        .listStyle(.insetGrouped)
    }
    
    /// Statistics header showing word counts.
    private var statsHeader: some View {
        Section {
            HStack(spacing: 0) {
                StatPill(
                    count: vocabViewModel.totalWordCount,
                    label: "Total",
                    color: .blue
                )
                
                Divider()
                    .frame(height: 40)
                
                StatPill(
                    count: vocabViewModel.learningWords.count,
                    label: "Learning",
                    color: .orange
                )
                
                Divider()
                    .frame(height: 40)
                
                StatPill(
                    count: vocabViewModel.masteredCount,
                    label: "Mastered",
                    color: .green
                )
            }
        }
    }
    
    /// Horizontal filter pills.
    private var filterPills: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(WordFilter.allCases, id: \.self) { filter in
                        FilterPill(
                            title: filter.rawValue,
                            isSelected: selectedFilter == filter
                        ) {
                            withAnimation {
                                selectedFilter = filter
                            }
                        }
                    }
                    
                    Divider()
                        .frame(height: 24)
                    
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        FilterPill(
                            title: order.rawValue,
                            isSelected: sortOrder == order
                        ) {
                            withAnimation {
                                sortOrder = order
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Menu for filter options.
    private var filterMenu: some View {
        Menu {
            Section("Filter") {
                ForEach(WordFilter.allCases, id: \.self) { filter in
                    Button {
                        selectedFilter = filter
                    } label: {
                        if selectedFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            }
            
            Section("Sort") {
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
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Gets the book title for a word.
    private func bookTitle(for word: VocabWord) -> String {
        booksViewModel.books.first { $0.id == word.bookId }?.title ?? "Unknown Book"
    }
    
    /// Deletes words at the specified offsets.
    private func deleteWords(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let word = displayedWords[index]
                await vocabViewModel.deleteWord(word)
            }
        }
    }
}

// MARK: - Stat Pill

/// A pill showing a count statistic.
struct StatPill: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Filter Pill

/// A selectable filter pill button.
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Vocab Row View

/// A row in the all words list showing word and book info.
struct AllVocabRowView: View {
    
    let word: VocabWord
    let bookTitle: String
    
    /// Access to vocab view model for actions.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Controls expansion of word details.
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Word header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(word.word)
                        .font(.headline)
                    
                    Text(bookTitle)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                // Mastered indicator
                Button {
                    Task {
                        await vocabViewModel.toggleMastered(word)
                    }
                } label: {
                    Image(systemName: word.mastered ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(word.mastered ? .green : .gray)
                }
                .buttonStyle(.plain)
            }
            
            // Definition
            Text(word.definition)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Expandable details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if !word.synonyms.isEmpty {
                        DetailRow(label: "Synonyms", value: word.synonyms.joined(separator: ", "))
                    }
                    
                    if !word.antonyms.isEmpty {
                        DetailRow(label: "Antonyms", value: word.antonyms.joined(separator: ", "))
                    }
                    
                    if !word.exampleSentence.isEmpty {
                        DetailRow(label: "Example", value: word.exampleSentence)
                    }
                }
                .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
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


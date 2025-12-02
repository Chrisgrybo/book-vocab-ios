//
//  BookDetailView.swift
//  BookVocab
//
//  Detail screen for a specific book.
//  Shows the list of vocabulary words and allows adding new words.
//

import SwiftUI

/// Detailed view for a single book showing its vocabulary words.
/// Provides navigation to add new vocabulary words.
struct BookDetailView: View {
    
    // MARK: - Properties
    
    /// The book being displayed.
    let book: Book
    
    // MARK: - Environment
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// Controls presentation of the Add Vocab sheet.
    @State private var showingAddVocab: Bool = false
    
    /// Search text for filtering words.
    @State private var searchText: String = ""
    
    /// Filter by mastered status.
    @State private var showMasteredOnly: Bool = false
    
    // MARK: - Computed Properties
    
    /// Vocabulary words for this book.
    private var bookWords: [VocabWord] {
        vocabViewModel.fetchWords(forBook: book.id)
    }
    
    /// Filtered vocabulary words.
    private var filteredWords: [VocabWord] {
        var words = bookWords
        
        if showMasteredOnly {
            words = words.filter { $0.mastered }
        }
        
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return words
    }
    
    /// Count of mastered words.
    private var masteredCount: Int {
        bookWords.filter { $0.mastered }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        List {
            // Book info header
            bookInfoSection
            
            // Stats section
            statsSection
            
            // Words list
            wordsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search words...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddVocab = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                Menu {
                    Toggle("Show Mastered Only", isOn: $showMasteredOnly)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddVocab) {
            AddVocabView(bookId: book.id)
        }
    }
    
    // MARK: - View Components
    
    /// Book information header.
    private var bookInfoSection: some View {
        Section {
            HStack(spacing: 16) {
                // Book cover
                Group {
                    if let coverUrl = book.coverImageUrl, !coverUrl.isEmpty {
                        AsyncImage(url: URL(string: coverUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            coverPlaceholder
                        }
                    } else {
                        coverPlaceholder
                    }
                }
                .frame(width: 80, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Added \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    /// Statistics about vocabulary progress.
    private var statsSection: some View {
        Section("Progress") {
            HStack {
                StatCard(
                    title: "Total Words",
                    value: "\(bookWords.count)",
                    icon: "textformat.abc"
                )
                
                Divider()
                
                StatCard(
                    title: "Mastered",
                    value: "\(masteredCount)",
                    icon: "checkmark.circle.fill"
                )
                
                Divider()
                
                StatCard(
                    title: "Learning",
                    value: "\(bookWords.count - masteredCount)",
                    icon: "book.fill"
                )
            }
            .padding(.vertical, 8)
        }
    }
    
    /// List of vocabulary words.
    private var wordsSection: some View {
        Section("Vocabulary Words") {
            if filteredWords.isEmpty {
                ContentUnavailableView {
                    Label("No Words Yet", systemImage: "text.book.closed")
                } description: {
                    Text("Add vocabulary words from this book.")
                } actions: {
                    Button {
                        showingAddVocab = true
                    } label: {
                        Text("Add Word")
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(filteredWords) { word in
                    VocabWordRowView(word: word)
                }
                .onDelete { offsets in
                    deleteWords(at: offsets)
                }
            }
        }
    }
    
    /// Placeholder for book covers.
    private var coverPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.blue.opacity(0.2))
            .overlay {
                Image(systemName: "book.closed.fill")
                    .font(.title)
                    .foregroundStyle(.blue.opacity(0.5))
            }
    }
    
    // MARK: - Actions
    
    /// Deletes words at the specified offsets.
    private func deleteWords(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let word = filteredWords[index]
                await vocabViewModel.deleteWord(word)
            }
        }
    }
}

// MARK: - Stat Card

/// A small card displaying a statistic.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vocab Word Row View

/// A row displaying a vocabulary word.
struct VocabWordRowView: View {
    
    /// The word to display.
    let word: VocabWord
    
    /// Access to vocab view model for actions.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Controls expansion of word details.
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Word header
            HStack {
                Text(word.word)
                    .font(.headline)
                
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

/// A row showing a label and value.
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.tertiary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: Book.sample)
            .environmentObject(VocabViewModel())
    }
}


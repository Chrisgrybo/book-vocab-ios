//
//  AddVocabView.swift
//  BookVocab
//
//  Premium sheet for adding vocabulary words.
//  Clean design with dictionary lookup and editable fields.
//
//  Features:
//  - Instant dictionary lookup
//  - Auto-populated fields
//  - Visual pill previews
//  - Smooth transitions
//  - Optional book picker for global words
//

import SwiftUI

struct AddVocabView: View {
    
    // MARK: - Properties
    
    /// The pre-assigned book ID. If nil, show book picker.
    /// When coming from a book detail view, this is set.
    /// When coming from the Words screen, this is nil.
    let preassignedBookId: UUID?
    
    /// Whether to show the book picker (only when preassignedBookId is nil)
    private var showBookPicker: Bool {
        preassignedBookId == nil
    }
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - State
    
    @State private var word: String = ""
    @State private var definition: String = ""
    @State private var synonymsText: String = ""
    @State private var antonymsText: String = ""
    @State private var exampleSentence: String = ""
    @State private var partOfSpeech: String = ""
    @State private var isLoading: Bool = false
    @State private var hasLookedUp: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var showUpgradeModal: Bool = false
    
    /// The selected book ID when using the book picker.
    /// Defaults to nil (global word / "All Words").
    @State private var selectedBookId: UUID? = nil
    
    /// The effective book ID to use when saving.
    /// Uses preassigned if available, otherwise the picker selection.
    private var effectiveBookId: UUID? {
        preassignedBookId ?? selectedBookId
    }
    
    private var isFormValid: Bool {
        !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Convenience Initializers
    
    /// Initialize with a specific book (from book detail view)
    init(bookId: UUID) {
        self.preassignedBookId = bookId
    }
    
    /// Initialize without a book (from Words screen)
    init() {
        self.preassignedBookId = nil
    }
    
    private var synonymsArray: [String] {
        synonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    private var antonymsArray: [String] {
        antonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Book picker (only when coming from Words screen)
                    if showBookPicker {
                        bookPickerSection
                    }
                    
                    // Word input with lookup
                    wordInputSection
                    
                    // Success indicator
                    if hasLookedUp {
                        successBanner
                    }
                    
                    // Definition
                    definitionSection
                    
                    // Synonyms & Antonyms
                    synonymsAntonymsSection
                    
                    // Example sentence
                    exampleSection
                }
                .padding(.horizontal, AppSpacing.horizontalPadding)
                .padding(.vertical, AppSpacing.lg)
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Add Word")
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
                        saveWord()
                    } label: {
                        Text("Save")
                            .fontWeight(.semibold)
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Lookup Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            // Upgrade modal for word limit
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeView(reason: .wordLimit)
            }
        }
    }
    
    // MARK: - Book Picker Section
    
    private var bookPickerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("Assign to Book", systemImage: "book.closed")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            Menu {
                // "None" option for global words
                Button {
                    selectedBookId = nil
                } label: {
                    HStack {
                        Text("None (All Words)")
                        if selectedBookId == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                // List all books
                ForEach(booksViewModel.books) { book in
                    Button {
                        selectedBookId = book.id
                    } label: {
                        HStack {
                            Text(book.title)
                            if selectedBookId == book.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let bookId = selectedBookId,
                       let book = booksViewModel.books.first(where: { $0.id == bookId }) {
                        // Show selected book
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(AppColors.primary)
                        Text(book.title)
                            .foregroundStyle(.primary)
                    } else {
                        // No book selected
                        Image(systemName: "tray.full")
                            .foregroundStyle(.secondary)
                        Text("None (All Words)")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
            
            Text("Leave as 'None' to add a global word not tied to any book")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Word Input Section
    
    private var wordInputSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label("Word", systemImage: "textformat")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
            
            HStack(spacing: AppSpacing.sm) {
                TextField("Enter a word", text: $word)
                    .font(.title3)
                    .fontWeight(.medium)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: word) { _, _ in
                        if hasLookedUp { hasLookedUp = false }
                    }
                
                // Lookup button
                Button {
                    Task { await lookupWord() }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background {
                        if word.isEmpty {
                            Color.gray.opacity(0.3)
                        } else {
                            AppColors.primary
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                }
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            .padding(AppSpacing.md)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            
            Text("Tap the search button to look up the definition")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    // MARK: - Success Banner
    
    private var successBanner: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.success)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Definition Found!")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !partOfSpeech.isEmpty {
                    Text(partOfSpeech.capitalized)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("Edit below")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(AppSpacing.md)
        .background(AppColors.success.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
    
    // MARK: - Definition Section
    
    private var definitionSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Label("Definition", systemImage: "text.book.closed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text("Required")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AppColors.warning.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            TextField("Enter or edit the definition", text: $definition, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
    
    // MARK: - Synonyms & Antonyms Section
    
    private var synonymsAntonymsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Synonyms
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Synonyms", systemImage: "equal.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Similar words (comma separated)", text: $synonymsText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                
                // Preview pills
                if !synonymsArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(synonymsArray.prefix(5), id: \.self) { synonym in
                                Text(synonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                            if synonymsArray.count > 5 {
                                Text("+\(synonymsArray.count - 5)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            
            // Antonyms
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Label("Antonyms", systemImage: "arrow.left.arrow.right.circle")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                TextField("Opposite words (comma separated)", text: $antonymsText)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .padding(AppSpacing.md)
                    .background(AppColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                
                // Preview pills
                if !antonymsArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(antonymsArray.prefix(5), id: \.self) { antonym in
                                Text(antonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                            if antonymsArray.count > 5 {
                                Text("+\(antonymsArray.count - 5)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Example Section
    
    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Label("Example Sentence", systemImage: "text.quote")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Text("Optional")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            TextField("An example sentence using the word", text: $exampleSentence, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.plain)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
    }
    
    // MARK: - Actions
    
    private func lookupWord() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await DictionaryService.shared.fetchWord(word)
            
            await MainActor.run {
                withAnimation(AppAnimation.spring) {
                    // IMPORTANT: Clear all fields BEFORE populating with new data
                    // This ensures stale data from a previous lookup doesn't persist
                    // if the new word is missing certain fields (synonyms, antonyms, etc.)
                    definition = ""
                    synonymsText = ""
                    antonymsText = ""
                    exampleSentence = ""
                    partOfSpeech = ""
                    
                    // Now populate only with fields returned by the API
                    if let primaryDef = DictionaryService.shared.getPrimaryDefinition(from: result) {
                        definition = primaryDef
                    }
                    
                    let synonyms = DictionaryService.shared.extractSynonyms(from: result)
                    if !synonyms.isEmpty {
                        synonymsText = synonyms.joined(separator: ", ")
                    }
                    
                    let antonyms = DictionaryService.shared.extractAntonyms(from: result)
                    if !antonyms.isEmpty {
                        antonymsText = antonyms.joined(separator: ", ")
                    }
                    
                    if let example = DictionaryService.shared.getFirstExample(from: result) {
                        exampleSentence = example
                    }
                    
                    if let pos = DictionaryService.shared.getPrimaryPartOfSpeech(from: result) {
                        partOfSpeech = pos
                    }
                    
                    hasLookedUp = true
                }
            }
        } catch let error as DictionaryError {
            errorMessage = error.localizedDescription
            showingError = true
        } catch {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            showingError = true
        }
        
        isLoading = false
    }
    
    private func saveWord() {
        // Check word limit for free users (only if word is assigned to a book)
        if let bookId = effectiveBookId {
            let currentWordCount = vocabViewModel.fetchWords(forBook: bookId).count
            if !subscriptionManager.canAddWord(currentCount: currentWordCount) {
                subscriptionManager.promptUpgrade(reason: .wordLimit)
                showUpgradeModal = true
                return
            }
        }
        
        let vocabWord = VocabWord(
            bookId: effectiveBookId,
            word: word.trimmingCharacters(in: .whitespacesAndNewlines).capitalized,
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
            synonyms: synonymsArray,
            antonyms: antonymsArray,
            exampleSentence: exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines),
            mastered: false
        )
        
        Task {
            await vocabViewModel.addWord(vocabWord)
            dismiss()
        }
    }
    
    /// Current word count for the selected book (for limit display)
    private var currentWordCountForBook: Int {
        guard let bookId = effectiveBookId else { return 0 }
        return vocabViewModel.fetchWords(forBook: bookId).count
    }
}

// MARK: - Preview

#Preview("With Book") {
    AddVocabView(bookId: UUID())
        .environmentObject(VocabViewModel())
        .environmentObject(BooksViewModel())
}

#Preview("Without Book (Book Picker)") {
    AddVocabView()
        .environmentObject(VocabViewModel())
        .environmentObject(BooksViewModel())
}

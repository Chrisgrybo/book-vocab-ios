//
//  AddVocabView.swift
//  BookVocab
//
//  Screen for adding a new vocabulary word.
//  Fetches definition, synonyms, antonyms, and example sentences
//  using the DictionaryService, then saves to Supabase.
//

import SwiftUI

/// View for adding a new vocabulary word to a book.
/// Supports automatic dictionary lookup for word details.
///
/// Flow:
/// 1. User enters a word
/// 2. User taps "Lookup" to fetch definition from Free Dictionary API
/// 3. Fields are populated automatically (user can edit)
/// 4. User taps "Save" to add word to the book's vocabulary list
struct AddVocabView: View {
    
    // MARK: - Properties
    
    /// The ID of the book to add the word to.
    let bookId: UUID
    
    // MARK: - Environment
    
    /// Dismiss action for the sheet.
    @Environment(\.dismiss) private var dismiss
    
    /// Access to the shared vocab view model for saving words.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// The word to add (user input).
    @State private var word: String = ""
    
    /// The word's definition (populated from API or manual entry).
    @State private var definition: String = ""
    
    /// Synonyms for the word (comma-separated string for editing).
    @State private var synonymsText: String = ""
    
    /// Antonyms for the word (comma-separated string for editing).
    @State private var antonymsText: String = ""
    
    /// Example sentence using the word.
    @State private var exampleSentence: String = ""
    
    /// Part of speech (noun, verb, etc.) - informational only.
    @State private var partOfSpeech: String = ""
    
    /// Loading state during dictionary lookup.
    @State private var isLoading: Bool = false
    
    /// Whether the word has been successfully looked up.
    @State private var hasLookedUp: Bool = false
    
    /// Error message to display in alert.
    @State private var errorMessage: String?
    
    /// Controls the error alert presentation.
    @State private var showingError: Bool = false
    
    // MARK: - Computed Properties
    
    /// Validates that required fields are filled.
    /// Word and definition are required; other fields are optional.
    private var isFormValid: Bool {
        let hasWord = !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasDefinition = !definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return hasWord && hasDefinition
    }
    
    /// Converts comma-separated synonyms text to array.
    /// Trims whitespace and filters out empty strings.
    private var synonymsArray: [String] {
        synonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Converts comma-separated antonyms text to array.
    /// Trims whitespace and filters out empty strings.
    private var antonymsArray: [String] {
        antonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Word input with lookup button
                wordInputSection
                
                // Part of speech (if available)
                if !partOfSpeech.isEmpty {
                    partOfSpeechSection
                }
                
                // Definition input
                definitionSection
                
                // Synonyms & Antonyms inputs
                synonymsAntonymsSection
                
                // Example sentence input
                exampleSection
            }
            .navigationTitle("Add Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel button - dismisses without saving
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                // Save button - saves word to Supabase
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWord()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            // Error alert for lookup failures
            .alert("Lookup Failed", isPresented: $showingError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Word input field with lookup button.
    /// Shows success indicator after successful lookup.
    private var wordInputSection: some View {
        Section {
            HStack {
                // Word text field
                TextField("Enter word", text: $word)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .onChange(of: word) { _, _ in
                        // Reset lookup status when word changes
                        if hasLookedUp {
                            hasLookedUp = false
                        }
                    }
                
                // Lookup button
                Button {
                    Task {
                        await lookupWord()
                    }
                } label: {
                    if isLoading {
                        // Show spinner during lookup
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        // Show magnifying glass icon
                        Image(systemName: "magnifyingglass")
                    }
                }
                .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
            }
            
            // Success indicator after lookup
            if hasLookedUp {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Definition found! You can edit fields below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Word")
        } footer: {
            Text("Enter a word and tap the search icon to look up its definition.")
        }
    }
    
    /// Displays the part of speech (noun, verb, etc.).
    /// Only shown when a word has been looked up.
    private var partOfSpeechSection: some View {
        Section("Part of Speech") {
            Text(partOfSpeech.capitalized)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Definition text field (multi-line).
    private var definitionSection: some View {
        Section {
            TextField("Enter definition", text: $definition, axis: .vertical)
                .lineLimit(3...6)
        } header: {
            Text("Definition")
        } footer: {
            Text("Required. The definition will be saved with the word.")
        }
    }
    
    /// Synonyms and antonyms input fields.
    /// Shows pill-style previews of entered words.
    private var synonymsAntonymsSection: some View {
        Section {
            // Synonyms text field
            TextField("Synonyms (comma separated)", text: $synonymsText)
                .autocapitalization(.none)
            
            // Antonyms text field
            TextField("Antonyms (comma separated)", text: $antonymsText)
                .autocapitalization(.none)
            
            // Visual preview of synonyms/antonyms as pills
            if !synonymsArray.isEmpty || !antonymsArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    // Synonyms pills
                    if !synonymsArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("Synonyms:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(synonymsArray.prefix(5), id: \.self) { synonym in
                                    Text(synonym)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                if synonymsArray.count > 5 {
                                    Text("+\(synonymsArray.count - 5) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Antonyms pills
                    if !antonymsArray.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                Text("Antonyms:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                ForEach(antonymsArray.prefix(5), id: \.self) { antonym in
                                    Text(antonym)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.red.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                if antonymsArray.count > 5 {
                                    Text("+\(antonymsArray.count - 5) more")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        } header: {
            Text("Synonyms & Antonyms")
        } footer: {
            Text("Optional. Separate multiple words with commas.")
        }
    }
    
    /// Example sentence text field (multi-line).
    private var exampleSection: some View {
        Section {
            TextField("Enter an example sentence", text: $exampleSentence, axis: .vertical)
                .lineLimit(2...4)
        } header: {
            Text("Example Sentence")
        } footer: {
            Text("Optional. An example helps reinforce learning.")
        }
    }
    
    // MARK: - Actions
    
    /// Looks up the word using the DictionaryService.
    /// Populates all fields with the API response data.
    private func lookupWord() async {
        // Set loading state
        isLoading = true
        errorMessage = nil
        
        do {
            // Call the Dictionary API via our service
            let result = try await DictionaryService.shared.fetchWord(word)
            
            // Extract and populate the definition
            if let primaryDefinition = DictionaryService.shared.getPrimaryDefinition(from: result) {
                definition = primaryDefinition
            }
            
            // Extract and populate synonyms (as comma-separated string)
            let synonyms = DictionaryService.shared.extractSynonyms(from: result)
            if !synonyms.isEmpty {
                synonymsText = synonyms.joined(separator: ", ")
            }
            
            // Extract and populate antonyms (as comma-separated string)
            let antonyms = DictionaryService.shared.extractAntonyms(from: result)
            if !antonyms.isEmpty {
                antonymsText = antonyms.joined(separator: ", ")
            }
            
            // Extract and populate example sentence
            if let example = DictionaryService.shared.getFirstExample(from: result) {
                exampleSentence = example
            }
            
            // Extract and populate part of speech
            if let pos = DictionaryService.shared.getPrimaryPartOfSpeech(from: result) {
                partOfSpeech = pos
            }
            
            // Mark as successfully looked up
            hasLookedUp = true
            
        } catch let error as DictionaryError {
            // Handle dictionary-specific errors with user-friendly messages
            errorMessage = error.localizedDescription
            showingError = true
        } catch {
            // Handle unexpected errors
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
            showingError = true
        }
        
        // Clear loading state
        isLoading = false
    }
    
    /// Saves the vocabulary word to the user's collection via VocabViewModel.
    /// Creates a VocabWord model and calls the ViewModel's addWord method.
    private func saveWord() {
        // Create the VocabWord model with all entered data
        let vocabWord = VocabWord(
            bookId: bookId,
            word: word.trimmingCharacters(in: .whitespacesAndNewlines).capitalized,
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines),
            synonyms: synonymsArray,
            antonyms: antonymsArray,
            exampleSentence: exampleSentence.trimmingCharacters(in: .whitespacesAndNewlines),
            mastered: false  // New words default to not mastered
        )
        
        // Save via the ViewModel (which will call SupabaseService)
        Task {
            await vocabViewModel.addWord(vocabWord)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    AddVocabView(bookId: UUID())
        .environmentObject(VocabViewModel())
}

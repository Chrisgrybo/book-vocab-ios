//
//  AddVocabView.swift
//  BookVocab
//
//  Screen for adding a new vocabulary word.
//  Fetches definition, synonyms, antonyms, and example sentences.
//

import SwiftUI

/// View for adding a new vocabulary word to a book.
/// Supports automatic dictionary lookup for word details.
struct AddVocabView: View {
    
    // MARK: - Properties
    
    /// The ID of the book to add the word to.
    let bookId: UUID
    
    // MARK: - Environment
    
    /// Dismiss action for the sheet.
    @Environment(\.dismiss) private var dismiss
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// The word to add.
    @State private var word: String = ""
    
    /// The word's definition.
    @State private var definition: String = ""
    
    /// Synonyms for the word.
    @State private var synonymsText: String = ""
    
    /// Antonyms for the word.
    @State private var antonymsText: String = ""
    
    /// Example sentence using the word.
    @State private var exampleSentence: String = ""
    
    /// Loading state for dictionary lookup.
    @State private var isLoading: Bool = false
    
    /// Whether the word has been looked up.
    @State private var hasLookedUp: Bool = false
    
    /// Error message from lookup.
    @State private var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// Validates that required fields are filled.
    private var isFormValid: Bool {
        !word.isEmpty && !definition.isEmpty
    }
    
    /// Converts comma-separated synonyms text to array.
    private var synonymsArray: [String] {
        synonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Converts comma-separated antonyms text to array.
    private var antonymsArray: [String] {
        antonymsText.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // Word input section
                wordInputSection
                
                // Definition section
                definitionSection
                
                // Synonyms & Antonyms
                synonymsAntonymsSection
                
                // Example sentence
                exampleSection
            }
            .navigationTitle("Add Word")
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
                        saveWord()
                    }
                    .disabled(!isFormValid || isLoading)
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Word input with lookup button.
    private var wordInputSection: some View {
        Section("Word") {
            HStack {
                TextField("Enter word", text: $word)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                
                Button {
                    Task {
                        await lookupWord()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Image(systemName: "magnifyingglass")
                    }
                }
                .disabled(word.isEmpty || isLoading)
            }
            
            if hasLookedUp {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Word looked up successfully")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    /// Definition input.
    private var definitionSection: some View {
        Section("Definition") {
            TextField("Enter definition", text: $definition, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    /// Synonyms and antonyms inputs.
    private var synonymsAntonymsSection: some View {
        Section("Synonyms & Antonyms") {
            TextField("Synonyms (comma separated)", text: $synonymsText)
                .autocapitalization(.none)
            
            TextField("Antonyms (comma separated)", text: $antonymsText)
                .autocapitalization(.none)
            
            if !synonymsArray.isEmpty || !antonymsArray.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !synonymsArray.isEmpty {
                        HStack {
                            Text("Synonyms:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(synonymsArray, id: \.self) { synonym in
                                Text(synonym)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if !antonymsArray.isEmpty {
                        HStack {
                            Text("Antonyms:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            ForEach(antonymsArray, id: \.self) { antonym in
                                Text(antonym)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Example sentence input.
    private var exampleSection: some View {
        Section("Example Sentence") {
            TextField("Enter an example sentence", text: $exampleSentence, axis: .vertical)
                .lineLimit(2...4)
        }
    }
    
    // MARK: - Actions
    
    /// Looks up the word in the dictionary.
    private func lookupWord() async {
        isLoading = true
        errorMessage = nil
        
        // TODO: Implement actual dictionary lookup
        // let response = try await DictionaryService.shared.lookupWord(word)
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Placeholder: Set mock data
        definition = "Definition for '\(word)' - connect dictionary API to fetch"
        synonymsText = "similar1, similar2"
        antonymsText = "opposite1, opposite2"
        exampleSentence = "This is an example sentence using \(word)."
        
        hasLookedUp = true
        isLoading = false
    }
    
    /// Saves the word to the vocab list.
    private func saveWord() {
        let vocabWord = VocabWord(
            bookId: bookId,
            word: word.capitalized,
            definition: definition,
            synonyms: synonymsArray,
            antonyms: antonymsArray,
            exampleSentence: exampleSentence
        )
        
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


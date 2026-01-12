//
//  EditWordView.swift
//  BookVocab
//
//  View for editing an existing vocabulary word.
//  Allows updating word text, definition, synonyms, antonyms, and example sentence.
//
//  Features:
//  - Pre-filled fields with existing word data
//  - Validation before saving
//  - Saves to local cache and syncs with Supabase
//  - Success/error feedback
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "EditWordView")

/// View for editing an existing vocabulary word.
struct EditWordView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - Properties
    
    /// The word being edited
    let word: VocabWord
    
    // MARK: - State
    
    @State private var editedWord: String
    @State private var editedDefinition: String
    @State private var editedSynonyms: String
    @State private var editedAntonyms: String
    @State private var editedExample: String
    @State private var isSaving: Bool = false
    @State private var showSaveSuccess: Bool = false
    @State private var errorMessage: String?
    @State private var hasAppeared: Bool = false
    
    // MARK: - Initialization
    
    init(word: VocabWord) {
        self.word = word
        // Initialize state with existing word data
        _editedWord = State(initialValue: word.word)
        _editedDefinition = State(initialValue: word.definition)
        _editedSynonyms = State(initialValue: word.synonyms.joined(separator: ", "))
        _editedAntonyms = State(initialValue: word.antonyms.joined(separator: ", "))
        _editedExample = State(initialValue: word.exampleSentence)
    }
    
    // MARK: - Computed Properties
    
    /// Validates that required fields are filled
    private var isFormValid: Bool {
        !editedWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !editedDefinition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Checks if any changes were made
    private var hasChanges: Bool {
        editedWord != word.word ||
        editedDefinition != word.definition ||
        editedSynonyms != word.synonyms.joined(separator: ", ") ||
        editedAntonyms != word.antonyms.joined(separator: ", ") ||
        editedExample != word.exampleSentence
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Word field
                    fieldSection(
                        title: "Word",
                        placeholder: "Enter word",
                        text: $editedWord,
                        icon: "textformat"
                    )
                    
                    // Definition field
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        fieldLabel(title: "Definition", icon: "text.book.closed")
                        
                        TextEditor(text: $editedDefinition)
                            .frame(minHeight: 80)
                            .padding(AppSpacing.sm)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                    
                    // Synonyms field
                    fieldSection(
                        title: "Synonyms",
                        placeholder: "Enter synonyms (comma-separated)",
                        text: $editedSynonyms,
                        icon: "equal.circle"
                    )
                    
                    // Antonyms field
                    fieldSection(
                        title: "Antonyms",
                        placeholder: "Enter antonyms (comma-separated)",
                        text: $editedAntonyms,
                        icon: "arrow.left.arrow.right.circle"
                    )
                    
                    // Example sentence field
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        fieldLabel(title: "Example Sentence", icon: "text.quote")
                        
                        TextEditor(text: $editedExample)
                            .frame(minHeight: 60)
                            .padding(AppSpacing.sm)
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                    
                    // Save button
                    saveButton
                        .padding(.horizontal, AppSpacing.horizontalPadding)
                        .padding(.top, AppSpacing.md)
                }
                .padding(.vertical, AppSpacing.lg)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Edit Word")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                withAnimation(AppAnimation.spring.delay(0.1)) {
                    hasAppeared = true
                }
            }
            // Error alert
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
            // Success alert
            .alert("Saved", isPresented: $showSaveSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Word updated successfully.")
            }
        }
    }
    
    // MARK: - View Components
    
    /// Reusable field section
    private func fieldSection(title: String, placeholder: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            fieldLabel(title: title, icon: icon)
            
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
        }
        .padding(.horizontal, AppSpacing.horizontalPadding)
    }
    
    /// Field label with icon
    private func fieldLabel(title: String, icon: String) -> some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }
    
    /// Save button
    private var saveButton: some View {
        Button {
            Task {
                await saveChanges()
            }
        } label: {
            HStack(spacing: AppSpacing.sm) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.headline)
                    Text("Save Changes")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                    .fill(isFormValid && hasChanges ? AppColors.primary : Color.gray.opacity(0.3))
            )
            .foregroundStyle(.white)
        }
        .disabled(!isFormValid || !hasChanges || isSaving)
        .animation(AppAnimation.smooth, value: isFormValid)
        .animation(AppAnimation.smooth, value: hasChanges)
    }
    
    // MARK: - Actions
    
    /// Saves the edited word
    private func saveChanges() async {
        // Dismiss keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        isSaving = true
        errorMessage = nil
        
        logger.info("✏️ Saving changes for word: '\(word.word)' -> '\(editedWord)'")
        
        // Parse synonyms and antonyms from comma-separated strings
        let synonymsArray = editedSynonyms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        let antonymsArray = editedAntonyms
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Create updated word
        var updatedWord = word
        updatedWord.word = editedWord.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedWord.definition = editedDefinition.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedWord.synonyms = synonymsArray
        updatedWord.antonyms = antonymsArray
        updatedWord.exampleSentence = editedExample.trimmingCharacters(in: .whitespacesAndNewlines)
        
        do {
            try await vocabViewModel.updateWord(updatedWord)
            
            logger.info("✅ Word updated successfully: '\(updatedWord.word)'")
            
            // Show success and dismiss
            showSaveSuccess = true
            
        } catch {
            logger.error("❌ Failed to update word: \(error.localizedDescription)")
            errorMessage = "Failed to save changes: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
}

// MARK: - Preview

#Preview {
    EditWordView(word: VocabWord.sample)
        .environmentObject(VocabViewModel())
}



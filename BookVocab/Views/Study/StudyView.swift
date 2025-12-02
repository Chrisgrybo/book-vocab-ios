//
//  StudyView.swift
//  BookVocab
//
//  Main study section providing access to flashcards and quizzes.
//  Users can select which book's vocabulary to study or review all words.
//
//  Features:
//  - Book/source selection for study
//  - Flashcard mode with flip and swipe
//  - Multiple choice quiz
//  - Fill-in-the-blank quiz
//  - Progress statistics
//  - Empty state handling
//

import SwiftUI
import os.log

/// Logger for StudyView debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "StudyView")

// MARK: - Study View

/// Main study section view providing access to flashcards and quizzes.
/// Users can select which vocabulary words to study and choose their study mode.
struct StudyView: View {
    
    // MARK: - Environment
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Access to the shared books view model.
    @EnvironmentObject var booksViewModel: BooksViewModel
    
    // MARK: - State
    
    /// Controls presentation of the flashcard session.
    @State private var showingFlashcards: Bool = false
    
    /// Controls presentation of the multiple choice quiz.
    @State private var showingMultipleChoice: Bool = false
    
    /// Controls presentation of the fill-in-blank quiz.
    @State private var showingFillInBlank: Bool = false
    
    /// Controls presentation of the source selection sheet.
    @State private var showingSourceSelection: Bool = false
    
    /// The currently selected study source.
    @State private var selectedSource: StudySource = .allWords
    
    /// Whether to study only learning words (not mastered).
    @State private var learningOnly: Bool = true
    
    /// The study mode being launched.
    @State private var pendingMode: StudyMode?
    
    // MARK: - Computed Properties
    
    /// Words available for the selected source.
    private var availableWords: [VocabWord] {
        switch selectedSource {
        case .allWords:
            return vocabViewModel.allWords
        case .book(let book):
            return vocabViewModel.fetchWords(forBook: book.id)
        }
    }
    
    /// Words available for study (filtered by learning status if needed).
    private var studyableWords: [VocabWord] {
        if learningOnly {
            return availableWords.filter { !$0.mastered }
        }
        return availableWords
    }
    
    /// Check if there are enough words to study.
    private var hasEnoughWords: Bool {
        studyableWords.count >= 1
    }
    
    /// Check if there are enough words for a quiz (need 4 for multiple choice).
    private var hasEnoughForQuiz: Bool {
        availableWords.count >= 4
    }
    
    /// Number of mastered words in selected source.
    private var masteredCount: Int {
        availableWords.filter { $0.mastered }.count
    }
    
    /// Number of learning words in selected source.
    private var learningCount: Int {
        availableWords.filter { !$0.mastered }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Source selection card
                    sourceSelectionCard
                    
                    // Stats overview
                    statsCard
                    
                    // Study modes
                    studyModesSection
                    
                    // Quick review section
                    if hasEnoughWords {
                        quickReviewSection
                    }
                }
                .padding()
            }
            .navigationTitle("Study")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingSourceSelection) {
                SourceSelectionSheet(
                    selectedSource: $selectedSource,
                    vocabViewModel: vocabViewModel,
                    booksViewModel: booksViewModel
                )
            }
            .fullScreenCover(isPresented: $showingFlashcards) {
                FlashcardSessionView(source: selectedSource, learningOnly: learningOnly)
            }
            .fullScreenCover(isPresented: $showingMultipleChoice) {
                QuizSessionView(source: selectedSource, quizMode: .multipleChoice)
            }
            .fullScreenCover(isPresented: $showingFillInBlank) {
                QuizSessionView(source: selectedSource, quizMode: .fillInBlank)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Card for selecting which words to study.
    private var sourceSelectionCard: some View {
        Button {
            showingSourceSelection = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Studying")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(selectedSource.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("\(studyableWords.count) words available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    /// Card showing vocabulary statistics.
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                Spacer()
                
                // Learning only toggle - filters out mastered words
                Toggle(isOn: $learningOnly) {
                    Text("Learning only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .toggleStyle(.switch)
                .scaleEffect(0.85)
                .fixedSize()
            }
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(availableWords.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Total Words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack {
                    Text("\(masteredCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack {
                    Text("\(learningCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Learning")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            if availableWords.count > 0 {
                let progress = Double(masteredCount) / Double(availableWords.count)
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .tint(.green)
                    Text("\(Int(progress * 100))% mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
    
    /// Section showing available study modes.
    private var studyModesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Modes")
                .font(.headline)
            
            // Flashcards
            StudyModeCard(
                icon: "rectangle.on.rectangle.angled",
                title: "Flashcards",
                description: "Review words with flip cards. Swipe right to mark as mastered.",
                color: .blue,
                wordCount: studyableWords.count,
                isDisabled: !hasEnoughWords
            ) {
                logger.info("📚 Launching flashcards for \(selectedSource.displayName)")
                showingFlashcards = true
            }
            
            // Multiple Choice Quiz
            StudyModeCard(
                icon: "list.bullet.circle",
                title: "Multiple Choice",
                description: "Choose the correct definition from 4 options.",
                color: .purple,
                wordCount: availableWords.count,
                isDisabled: !hasEnoughForQuiz
            ) {
                logger.info("📚 Launching multiple choice quiz for \(selectedSource.displayName)")
                showingMultipleChoice = true
            }
            
            // Fill in the Blank Quiz
            StudyModeCard(
                icon: "pencil.line",
                title: "Fill in the Blank",
                description: "Type the word that matches the definition.",
                color: .orange,
                wordCount: availableWords.count,
                isDisabled: !hasEnoughForQuiz
            ) {
                logger.info("📚 Launching fill-in-blank quiz for \(selectedSource.displayName)")
                showingFillInBlank = true
            }
        }
    }
    
    /// Quick review section with shortcuts.
    private var quickReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Review All",
                    subtitle: "\(availableWords.count) words",
                    color: .blue,
                    isDisabled: availableWords.isEmpty
                ) {
                    learningOnly = false
                    showingFlashcards = true
                }
                
                QuickActionButton(
                    icon: "star.fill",
                    title: "Learning Only",
                    subtitle: "\(learningCount) words",
                    color: .orange,
                    isDisabled: learningCount == 0
                ) {
                    learningOnly = true
                    showingFlashcards = true
                }
            }
        }
    }
}

// MARK: - Source Selection Sheet

/// Sheet for selecting which book's words to study.
struct SourceSelectionSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSource: StudySource
    let vocabViewModel: VocabViewModel
    let booksViewModel: BooksViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // All Words option
                Section {
                    SourceRow(
                        source: .allWords,
                        wordCount: vocabViewModel.totalWordCount,
                        masteredCount: vocabViewModel.masteredCount,
                        isSelected: selectedSource == .allWords
                    ) {
                        selectedSource = .allWords
                        dismiss()
                    }
                }
                
                // Books section
                Section("By Book") {
                    if booksViewModel.books.isEmpty {
                        Text("No books added yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(booksViewModel.books) { book in
                            let words = vocabViewModel.fetchWords(forBook: book.id)
                            let mastered = words.filter { $0.mastered }.count
                            
                            SourceRow(
                                source: .book(book),
                                wordCount: words.count,
                                masteredCount: mastered,
                                isSelected: selectedSource == .book(book)
                            ) {
                                selectedSource = .book(book)
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Words to Study")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Source Row

/// A row in the source selection list.
struct SourceRow: View {
    let source: StudySource
    let wordCount: Int
    let masteredCount: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(source.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 12) {
                        Label("\(wordCount) words", systemImage: "textformat.abc")
                        Label("\(masteredCount) mastered", systemImage: "checkmark.circle")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(wordCount == 0)
        .opacity(wordCount == 0 ? 0.5 : 1)
    }
}

// MARK: - Study Mode Card

/// A card representing a study mode option.
struct StudyModeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let wordCount: Int
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .gray : color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(isDisabled ? 0.1 : 0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(isDisabled ? .gray : .primary)
                        
                        if isDisabled {
                            Text("(\(wordCount) words)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Quick Action Button

/// A quick action button.
struct QuickActionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isDisabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isDisabled ? .gray : color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(isDisabled ? .gray : .primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Preview

#Preview {
    StudyView()
        .environmentObject(VocabViewModel())
        .environmentObject(BooksViewModel())
}

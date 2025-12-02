//
//  StudyView.swift
//  BookVocab
//
//  Study section placeholder for flashcards and quizzes.
//  Will be expanded with full study functionality later.
//

import SwiftUI

/// Main study section view providing access to flashcards and quizzes.
/// This is a placeholder that will be expanded with full study functionality.
struct StudyView: View {
    
    // MARK: - Environment
    
    /// Access to the shared vocab view model.
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    /// Controls presentation of the flashcard view.
    @State private var showingFlashcards: Bool = false
    
    /// Controls presentation of the quiz view.
    @State private var showingQuiz: Bool = false
    
    // MARK: - Computed Properties
    
    /// Check if there are enough words to study.
    private var hasEnoughWords: Bool {
        vocabViewModel.learningWords.count >= 1
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats overview
                    statsCard
                    
                    // Study modes
                    studyModesSection
                    
                    // Quick actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Study")
            .sheet(isPresented: $showingFlashcards) {
                FlashcardsPlaceholderView()
            }
            .sheet(isPresented: $showingQuiz) {
                QuizPlaceholderView()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Card showing vocabulary statistics.
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Progress")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(vocabViewModel.totalWordCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Total Words")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack {
                    Text("\(vocabViewModel.masteredCount)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("Mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider()
                    .frame(height: 50)
                
                VStack {
                    Text("\(vocabViewModel.learningWords.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("Learning")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Progress bar
            if vocabViewModel.totalWordCount > 0 {
                let progress = Double(vocabViewModel.masteredCount) / Double(vocabViewModel.totalWordCount)
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
                description: "Review words with flip cards",
                color: .blue,
                isDisabled: !hasEnoughWords
            ) {
                showingFlashcards = true
            }
            
            // Quiz
            StudyModeCard(
                icon: "questionmark.circle",
                title: "Quiz",
                description: "Test your knowledge",
                color: .purple,
                isDisabled: !hasEnoughWords
            ) {
                showingQuiz = true
            }
            
            // Spell Check (placeholder)
            StudyModeCard(
                icon: "textformat.abc",
                title: "Spell Check",
                description: "Coming soon",
                color: .orange,
                isDisabled: true
            ) {
                // TODO: Implement spell check mode
            }
        }
    }
    
    /// Quick action buttons.
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "arrow.clockwise",
                    title: "Review All",
                    color: .blue,
                    isDisabled: !hasEnoughWords
                ) {
                    showingFlashcards = true
                }
                
                QuickActionButton(
                    icon: "star.fill",
                    title: "Review Learning",
                    color: .orange,
                    isDisabled: !hasEnoughWords
                ) {
                    showingFlashcards = true
                }
            }
        }
    }
}

// MARK: - Study Mode Card

/// A card representing a study mode option.
struct StudyModeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
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
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(isDisabled ? .gray : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
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

// MARK: - Flashcards Placeholder View

/// Placeholder view for flashcards functionality.
struct FlashcardsPlaceholderView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
                
                Text("Flashcards")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Flashcard study mode coming soon!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder card
                VStack(spacing: 16) {
                    Text("Example Word")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Tap to flip")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Flashcards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Quiz Placeholder View

/// Placeholder view for quiz functionality.
struct QuizPlaceholderView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(.purple)
                
                Text("Quiz Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Quiz functionality coming soon!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder quiz card
                VStack(spacing: 16) {
                    Text("What does this word mean?")
                        .font(.headline)
                    
                    Text("?")
                        .font(.system(size: 48))
                        .foregroundStyle(.purple)
                    
                    Text("Multiple choice options")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)
            }
            .padding()
            .navigationTitle("Quiz")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StudyView()
        .environmentObject(VocabViewModel())
}


//
//  StudyViewModel.swift
//  BookVocab
//
//  ViewModel for managing study sessions (flashcards & quizzes).
//  Placeholder for future implementation.
//

import Foundation
import SwiftUI

/// Enum representing different study modes available.
enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards = "Flashcards"
    case quiz = "Quiz"
    case spellCheck = "Spell Check"
    
    var id: String { rawValue }
    
    /// SF Symbol name for each study mode.
    var iconName: String {
        switch self {
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .quiz: return "questionmark.circle"
        case .spellCheck: return "textformat.abc"
        }
    }
}

/// ViewModel responsible for managing study sessions.
/// Handles flashcard decks, quiz logic, and progress tracking.
@MainActor
class StudyViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently selected study mode.
    @Published var selectedMode: StudyMode = .flashcards
    
    /// Words available for the current study session.
    @Published var studyWords: [VocabWord] = []
    
    /// Index of the current word being studied.
    @Published var currentIndex: Int = 0
    
    /// Whether the current flashcard is showing the answer.
    @Published var isShowingAnswer: Bool = false
    
    /// Score for the current quiz session.
    @Published var quizScore: Int = 0
    
    /// Total questions answered in current session.
    @Published var questionsAnswered: Int = 0
    
    /// Whether a study session is currently active.
    @Published var isSessionActive: Bool = false
    
    // MARK: - Computed Properties
    
    /// The current word being studied.
    var currentWord: VocabWord? {
        guard currentIndex < studyWords.count else { return nil }
        return studyWords[currentIndex]
    }
    
    /// Progress through the current study session (0.0 to 1.0).
    var sessionProgress: Double {
        guard !studyWords.isEmpty else { return 0 }
        return Double(currentIndex) / Double(studyWords.count)
    }
    
    /// Whether there are more words to study.
    var hasMoreWords: Bool {
        currentIndex < studyWords.count - 1
    }
    
    // MARK: - Initialization
    
    /// Creates a new StudyViewModel.
    init() {
        // Load sample data for scaffolding
        #if DEBUG
        self.studyWords = VocabWord.samples
        #endif
    }
    
    // MARK: - Session Management
    
    /// Starts a new study session with the given words.
    /// - Parameters:
    ///   - words: Array of words to study
    ///   - mode: The study mode to use
    func startSession(with words: [VocabWord], mode: StudyMode) {
        studyWords = words.shuffled()
        selectedMode = mode
        currentIndex = 0
        isShowingAnswer = false
        quizScore = 0
        questionsAnswered = 0
        isSessionActive = true
    }
    
    /// Ends the current study session.
    func endSession() {
        isSessionActive = false
        currentIndex = 0
        isShowingAnswer = false
    }
    
    // MARK: - Flashcard Methods
    
    /// Flips the current flashcard to show/hide the answer.
    func flipCard() {
        isShowingAnswer.toggle()
    }
    
    /// Moves to the next word in the study session.
    func nextWord() {
        guard hasMoreWords else {
            endSession()
            return
        }
        currentIndex += 1
        isShowingAnswer = false
    }
    
    /// Moves to the previous word in the study session.
    func previousWord() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isShowingAnswer = false
    }
    
    // MARK: - Quiz Methods
    
    /// Records an answer for the current quiz question.
    /// - Parameter correct: Whether the answer was correct
    func recordAnswer(correct: Bool) {
        questionsAnswered += 1
        if correct {
            quizScore += 1
        }
    }
    
    /// Calculates the final quiz score as a percentage.
    /// - Returns: Score percentage (0-100)
    func calculateScorePercentage() -> Int {
        guard questionsAnswered > 0 else { return 0 }
        return Int((Double(quizScore) / Double(questionsAnswered)) * 100)
    }
}


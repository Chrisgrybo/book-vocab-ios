//
//  StudyViewModel.swift
//  BookVocab
//
//  ViewModel for managing study sessions (flashcards & quizzes).
//  Handles session state, progress tracking, and quiz answer validation.
//
//  DEBUG: Includes logging for flashcard flips, quiz answers, and mastered updates.
//

import Foundation
import SwiftUI
import os.log

/// Logger for StudyViewModel debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "StudyViewModel")

// MARK: - Study Mode Enum

/// Enum representing different study modes available.
enum StudyMode: String, CaseIterable, Identifiable {
    case flashcards = "Flashcards"
    case multipleChoice = "Multiple Choice"
    case fillInBlank = "Fill in the Blank"
    
    var id: String { rawValue }
    
    /// SF Symbol name for each study mode.
    var iconName: String {
        switch self {
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .multipleChoice: return "list.bullet.circle"
        case .fillInBlank: return "pencil.line"
        }
    }
    
    /// Description for each study mode.
    var description: String {
        switch self {
        case .flashcards: return "Review words with flip cards"
        case .multipleChoice: return "Choose the correct definition"
        case .fillInBlank: return "Type the word from its definition"
        }
    }
}

// MARK: - Quiz Question Model

/// Represents a single quiz question.
struct QuizQuestion: Identifiable {
    let id = UUID()
    let word: VocabWord
    let questionType: StudyMode
    let options: [String]  // For multiple choice
    let correctAnswer: String
    var userAnswer: String?
    var isCorrect: Bool?
    
    /// Creates a multiple choice question from a vocab word.
    static func multipleChoice(word: VocabWord, allWords: [VocabWord]) -> QuizQuestion {
        // Generate 4 options including the correct answer
        var options = [word.definition]
        
        // Get random wrong answers from other words
        let otherWords = allWords.filter { $0.id != word.id }
        let wrongAnswers = otherWords.shuffled().prefix(3).map { $0.definition }
        options.append(contentsOf: wrongAnswers)
        
        // If we don't have enough options, add placeholders
        while options.count < 4 {
            options.append("No definition available")
        }
        
        return QuizQuestion(
            word: word,
            questionType: .multipleChoice,
            options: options.shuffled(),
            correctAnswer: word.definition
        )
    }
    
    /// Creates a fill-in-the-blank question from a vocab word.
    static func fillInBlank(word: VocabWord) -> QuizQuestion {
        return QuizQuestion(
            word: word,
            questionType: .fillInBlank,
            options: [],
            correctAnswer: word.word.lowercased()
        )
    }
}

// MARK: - Study Session Result

/// Represents the result of a completed study session.
struct StudySessionResult: Identifiable {
    let id = UUID()
    let mode: StudyMode
    let totalQuestions: Int
    let correctAnswers: Int
    let masteredCount: Int
    let duration: TimeInterval
    let timestamp: Date
    
    var scorePercentage: Int {
        guard totalQuestions > 0 else { return 0 }
        return Int((Double(correctAnswers) / Double(totalQuestions)) * 100)
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Study Source Selection

/// Represents the source of words for study (specific book or all words).
enum StudySource: Identifiable, Hashable {
    case allWords
    case book(Book)
    
    var id: String {
        switch self {
        case .allWords: return "all"
        case .book(let book): return book.id.uuidString
        }
    }
    
    var displayName: String {
        switch self {
        case .allWords: return "All Words"
        case .book(let book): return book.title
        }
    }
}

// MARK: - Study ViewModel

/// ViewModel responsible for managing study sessions.
/// Handles flashcard decks, quiz logic, and progress tracking.
@MainActor
class StudyViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// The currently selected study mode.
    @Published var selectedMode: StudyMode = .flashcards
    
    /// The source of words for the current study session.
    @Published var selectedSource: StudySource = .allWords
    
    /// Words available for the current study session.
    @Published var studyWords: [VocabWord] = []
    
    /// Index of the current word being studied.
    @Published var currentIndex: Int = 0
    
    /// Whether the current flashcard is showing the answer (flipped).
    @Published var isFlipped: Bool = false
    
    /// Whether a study session is currently active.
    @Published var isSessionActive: Bool = false
    
    /// The current quiz questions.
    @Published var quizQuestions: [QuizQuestion] = []
    
    /// Index of the current quiz question.
    @Published var currentQuestionIndex: Int = 0
    
    /// Whether the quiz has been submitted for grading.
    @Published var isQuizComplete: Bool = false
    
    /// Words marked as mastered during this session.
    @Published var sessionMasteredWords: Set<UUID> = []
    
    /// Words skipped during this session.
    @Published var sessionSkippedWords: Set<UUID> = []
    
    /// Start time of the current session.
    @Published var sessionStartTime: Date?
    
    /// The result of the last completed session.
    @Published var lastSessionResult: StudySessionResult?
    
    /// Show session complete view.
    @Published var showSessionComplete: Bool = false
    
    // MARK: - Computed Properties
    
    /// The current word being studied in flashcard mode.
    var currentWord: VocabWord? {
        guard currentIndex >= 0 && currentIndex < studyWords.count else { return nil }
        return studyWords[currentIndex]
    }
    
    /// The current quiz question.
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex >= 0 && currentQuestionIndex < quizQuestions.count else { return nil }
        return quizQuestions[currentQuestionIndex]
    }
    
    /// Progress through the current study session (0.0 to 1.0).
    var sessionProgress: Double {
        guard !studyWords.isEmpty else { return 0 }
        return Double(currentIndex + 1) / Double(studyWords.count)
    }
    
    /// Progress through the current quiz (0.0 to 1.0).
    var quizProgress: Double {
        guard !quizQuestions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(quizQuestions.count)
    }
    
    /// Whether there are more words to study in flashcard mode.
    var hasMoreWords: Bool {
        currentIndex < studyWords.count - 1
    }
    
    /// Whether there are more questions in quiz mode.
    var hasMoreQuestions: Bool {
        currentQuestionIndex < quizQuestions.count - 1
    }
    
    /// Number of correct answers in the current quiz.
    var correctAnswersCount: Int {
        quizQuestions.filter { $0.isCorrect == true }.count
    }
    
    /// Session duration so far.
    var sessionDuration: TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    /// Formatted progress string for flashcards.
    var progressText: String {
        "\(currentIndex + 1) / \(studyWords.count)"
    }
    
    /// Formatted progress string for quiz.
    var quizProgressText: String {
        "Question \(currentQuestionIndex + 1) of \(quizQuestions.count)"
    }
    
    // MARK: - Dependencies
    
    /// Reference to the VocabViewModel for updating mastered status.
    weak var vocabViewModel: VocabViewModel?
    
    // MARK: - Initialization
    
    /// Creates a new StudyViewModel.
    init() {
        logger.info("📚 StudyViewModel initialized")
    }
    
    // MARK: - Session Management
    
    /// Starts a new flashcard study session.
    /// - Parameters:
    ///   - words: Array of words to study
    ///   - source: The source of the words (book or all)
    func startFlashcardSession(with words: [VocabWord], source: StudySource) {
        logger.info("🎴 Starting flashcard session with \(words.count) words from \(source.displayName)")
        
        guard !words.isEmpty else {
            logger.warning("🎴 Cannot start session with empty word list")
            return
        }
        
        studyWords = words.shuffled()
        selectedSource = source
        selectedMode = .flashcards
        currentIndex = 0
        isFlipped = false
        sessionMasteredWords = []
        sessionSkippedWords = []
        sessionStartTime = Date()
        isSessionActive = true
        showSessionComplete = false
        
        logger.debug("🎴 Session started: first word is '\(self.studyWords[0].word)'")
    }
    
    /// Starts a new quiz session.
    /// - Parameters:
    ///   - words: Array of words to quiz on
    ///   - source: The source of the words
    ///   - mode: Quiz type (multiple choice or fill in blank)
    func startQuizSession(with words: [VocabWord], source: StudySource, mode: StudyMode) {
        logger.info("❓ Starting \(mode.rawValue) quiz with \(words.count) words from \(source.displayName)")
        
        guard !words.isEmpty else {
            logger.warning("❓ Cannot start quiz with empty word list")
            return
        }
        
        let shuffledWords = words.shuffled()
        selectedSource = source
        selectedMode = mode
        sessionStartTime = Date()
        
        // Generate quiz questions based on mode
        if mode == .multipleChoice {
            quizQuestions = shuffledWords.prefix(10).map { word in
                QuizQuestion.multipleChoice(word: word, allWords: words)
            }
        } else {
            quizQuestions = shuffledWords.prefix(10).map { word in
                QuizQuestion.fillInBlank(word: word)
            }
        }
        
        currentQuestionIndex = 0
        isQuizComplete = false
        sessionMasteredWords = []
        isSessionActive = true
        showSessionComplete = false
        
        logger.debug("❓ Quiz started with \(self.quizQuestions.count) questions")
    }
    
    /// Ends the current study session and calculates results.
    func endSession() {
        logger.info("📚 Ending study session")
        
        let duration = sessionDuration
        var correctCount = 0
        var totalCount = 0
        
        if self.selectedMode == .flashcards {
            totalCount = self.studyWords.count
            correctCount = self.sessionMasteredWords.count
        } else {
            totalCount = self.quizQuestions.count
            correctCount = self.correctAnswersCount
        }
        
        lastSessionResult = StudySessionResult(
            mode: self.selectedMode,
            totalQuestions: totalCount,
            correctAnswers: correctCount,
            masteredCount: self.sessionMasteredWords.count,
            duration: duration,
            timestamp: Date()
        )
        
        logger.info("📚 Session complete: \(correctCount)/\(totalCount), mastered \(self.sessionMasteredWords.count) words")
        
        isSessionActive = false
        showSessionComplete = true
    }
    
    /// Resets the session state for a new session.
    func resetSession() {
        currentIndex = 0
        currentQuestionIndex = 0
        isFlipped = false
        isQuizComplete = false
        sessionMasteredWords = []
        sessionSkippedWords = []
        studyWords = []
        quizQuestions = []
        showSessionComplete = false
        isSessionActive = false
    }
    
    // MARK: - Flashcard Methods
    
    /// Flips the current flashcard to show/hide the answer.
    func flipCard() {
        isFlipped.toggle()
        logger.debug("🎴 Card flipped to \(self.isFlipped ? "answer" : "word") for '\(self.currentWord?.word ?? "unknown")'")
    }
    
    /// Moves to the next word in the flashcard session.
    func nextWord() {
        guard hasMoreWords else {
            logger.info("🎴 Reached end of flashcard session")
            endSession()
            return
        }
        
        currentIndex += 1
        isFlipped = false
        logger.debug("🎴 Moving to next word: '\(self.currentWord?.word ?? "unknown")' (\(self.currentIndex + 1)/\(self.studyWords.count))")
    }
    
    /// Moves to the previous word in the flashcard session.
    func previousWord() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        isFlipped = false
        logger.debug("🎴 Moving to previous word: '\(self.currentWord?.word ?? "unknown")'")
    }
    
    /// Marks the current word as "got it" (user knows it) and moves to next.
    /// Note: Words are NOT automatically marked as mastered in the database.
    /// The user can manually select words to master from the session summary screen.
    func markCurrentAsMastered() {
        guard let word = currentWord else { return }
        
        // Track that user "got" this word in the session
        sessionMasteredWords.insert(word.id)
        logger.info("✅ User marked '\(word.word)' as 'got it' (session total: \(self.sessionMasteredWords.count))")
        
        // NOTE: We no longer automatically mark words as mastered here.
        // Users will manually select which words to master from the summary screen.
        
        nextWord()
    }
    
    /// Skips the current word (swipe left) and moves to next.
    func skipCurrentWord() {
        guard let word = currentWord else { return }
        
        sessionSkippedWords.insert(word.id)
        logger.debug("⏭️ Skipped '\(word.word)'")
        
        nextWord()
    }
    
    // MARK: - Quiz Methods
    
    /// Submits an answer for the current quiz question.
    /// Note: Words are NOT automatically marked as mastered when correct.
    /// The user can manually select words to master from the quiz summary screen.
    /// - Parameter answer: The user's answer
    func submitAnswer(_ answer: String) {
        guard currentQuestionIndex < quizQuestions.count else { return }
        
        var question = quizQuestions[currentQuestionIndex]
        question.userAnswer = answer
        
        // Check if answer is correct
        if selectedMode == .multipleChoice {
            question.isCorrect = answer == question.correctAnswer
        } else {
            // Fill in blank - case insensitive comparison
            question.isCorrect = answer.lowercased().trimmingCharacters(in: .whitespaces) == question.correctAnswer.lowercased()
        }
        
        quizQuestions[currentQuestionIndex] = question
        
        let status = question.isCorrect == true ? "CORRECT" : "INCORRECT"
        logger.info("❓ Answer submitted for '\(question.word.word)': \(status)")
        logger.debug("❓ User answered: '\(answer)', Correct: '\(question.correctAnswer)'")
        
        // NOTE: We no longer automatically mark words as mastered here.
        // Users will manually select which words to master from the summary screen.
    }
    
    /// Moves to the next quiz question.
    func nextQuestion() {
        guard hasMoreQuestions else {
            logger.info("❓ Quiz complete")
            isQuizComplete = true
            endSession()
            return
        }
        
        currentQuestionIndex += 1
        logger.debug("❓ Moving to question \(self.currentQuestionIndex + 1)/\(self.quizQuestions.count)")
    }
    
    /// Calculates the final quiz score as a percentage.
    func calculateScorePercentage() -> Int {
        guard !quizQuestions.isEmpty else { return 0 }
        return Int((Double(correctAnswersCount) / Double(quizQuestions.count)) * 100)
    }
    
    /// Marks multiple words as mastered from the summary screen (quiz or flashcards).
    /// Called when the user taps "Save" on the summary screen.
    /// NOTE: This function ONLY updates mastered status. It does NOT delete any words.
    /// - Parameter wordIds: Set of word IDs to mark as mastered
    func markWordsAsMasteredFromSummary(wordIds: Set<UUID>) async {
        guard let vm = vocabViewModel else {
            logger.warning("❌ No VocabViewModel available to update mastered status")
            return
        }
        
        guard !wordIds.isEmpty else {
            logger.debug("📝 No words to mark as mastered, skipping")
            return
        }
        
        logger.info("✅ Starting to mark \(wordIds.count) words as mastered from summary")
        logger.debug("📝 Word IDs to mark: \(wordIds.map { $0.uuidString.prefix(8) })")
        
        var successCount = 0
        var skipCount = 0
        var notFoundCount = 0
        
        for wordId in wordIds {
            // Try to find the word in quiz questions first
            if let question = quizQuestions.first(where: { $0.word.id == wordId }) {
                let word = question.word
                if !word.mastered {
                    logger.debug("📝 Marking quiz word '\(word.word)' (ID: \(wordId.uuidString.prefix(8))) as mastered")
                    await vm.setMastered(word, to: true)
                    successCount += 1
                } else {
                    logger.debug("📝 Quiz word '\(word.word)' already mastered, skipping")
                    skipCount += 1
                }
            }
            // Also check flashcard study words
            else if let word = studyWords.first(where: { $0.id == wordId }) {
                if !word.mastered {
                    logger.debug("📝 Marking flashcard word '\(word.word)' (ID: \(wordId.uuidString.prefix(8))) as mastered")
                    await vm.setMastered(word, to: true)
                    successCount += 1
                } else {
                    logger.debug("📝 Flashcard word '\(word.word)' already mastered, skipping")
                    skipCount += 1
                }
            } else {
                logger.warning("⚠️ Word ID \(wordId.uuidString.prefix(8)) not found in quiz questions or study words")
                notFoundCount += 1
            }
        }
        
        logger.info("✅ Finished marking words as mastered:")
        logger.info("   - Successfully marked: \(successCount)")
        logger.info("   - Already mastered (skipped): \(skipCount)")
        logger.info("   - Not found: \(notFoundCount)")
    }
    
    /// Returns the words studied in the current flashcard session with their "got it" status.
    /// - Returns: Array of tuples containing the word and whether the user marked it as "got it"
    func getFlashcardSessionWords() -> [(word: VocabWord, gotIt: Bool)] {
        return studyWords.map { word in
            (word: word, gotIt: sessionMasteredWords.contains(word.id))
        }
    }
    
    // MARK: - Utility Methods
    
    /// Gets words for a specific study source.
    /// - Parameters:
    ///   - source: The study source
    ///   - vocabViewModel: The vocab view model containing all words
    /// - Returns: Array of vocab words from that source
    func getWords(for source: StudySource, from vocabViewModel: VocabViewModel) -> [VocabWord] {
        switch source {
        case .allWords:
            return vocabViewModel.allWords
        case .book(let book):
            return vocabViewModel.fetchWords(forBook: book.id)
        }
    }
    
    /// Gets words still being learned (not mastered) for a source.
    func getLearningWords(for source: StudySource, from vocabViewModel: VocabViewModel) -> [VocabWord] {
        return getWords(for: source, from: vocabViewModel).filter { !$0.mastered }
    }
}

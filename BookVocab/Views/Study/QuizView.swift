//
//  QuizView.swift
//  BookVocab
//
//  Quiz study mode with multiple choice and fill-in-the-blank formats.
//  Tests user knowledge and provides immediate feedback.
//
//  Features:
//  - Multiple choice questions
//  - Fill-in-the-blank questions
//  - Immediate feedback on answers
//  - Session score tracking
//  - Review of incorrect answers
//

import SwiftUI
import os.log

/// Logger for QuizView debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "QuizView")

// MARK: - Quiz Session View

/// Main view for quiz study sessions.
struct QuizSessionView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @StateObject private var studyVM = StudyViewModel()
    
    // MARK: - Properties
    
    /// The source of words for this quiz.
    let source: StudySource
    
    /// The type of quiz (multiple choice or fill in blank).
    let quizMode: StudyMode
    
    // MARK: - State
    
    @State private var showingExitConfirmation = false
    @State private var selectedAnswer: String? = nil
    @State private var showingFeedback = false
    @State private var userInput = ""
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if studyVM.showSessionComplete {
                    // Quiz complete view
                    QuizCompleteView(
                        result: studyVM.lastSessionResult,
                        questions: studyVM.quizQuestions
                    ) {
                        dismiss()
                    }
                } else if studyVM.quizQuestions.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Main quiz view
                    quizContent
                }
            }
            .navigationTitle(quizMode == .multipleChoice ? "Multiple Choice" : "Fill in the Blank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit") {
                        if studyVM.isSessionActive {
                            showingExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    }
                }
            }
            .confirmationDialog("Exit Quiz?", isPresented: $showingExitConfirmation) {
                Button("Exit", role: .destructive) {
                    studyVM.endSession()
                    dismiss()
                }
                Button("Continue Quiz", role: .cancel) { }
            } message: {
                Text("Your progress will be lost. You've answered \(studyVM.currentQuestionIndex) of \(studyVM.quizQuestions.count) questions.")
            }
            .onAppear {
                startQuiz()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state when no words available.
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Not Enough Words")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("You need at least 4 vocabulary words to take a quiz. Add more words first!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Go Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    /// Main quiz content.
    private var quizContent: some View {
        VStack(spacing: 0) {
            // Progress header
            quizProgressHeader
            
            // Question content
            if let question = studyVM.currentQuestion {
                ScrollView {
                    VStack(spacing: 24) {
                        // Question card
                        questionCard(question)
                        
                        // Answer section
                        if quizMode == .multipleChoice {
                            multipleChoiceAnswers(question)
                        } else {
                            fillInBlankAnswer(question)
                        }
                        
                        // Feedback (shown after answering)
                        if showingFeedback {
                            feedbackCard(question)
                        }
                    }
                    .padding()
                }
                
                // Next button
                if showingFeedback {
                    nextButton
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    /// Progress header for quiz.
    private var quizProgressHeader: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: studyVM.quizProgress)
                .tint(.purple)
                .padding(.horizontal)
            
            // Progress text
            HStack {
                Text(studyVM.quizProgressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Score
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(studyVM.correctAnswersCount) correct")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    /// Question card displaying the word or definition.
    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            // Question type label
            Label(
                quizMode == .multipleChoice ? "What is the definition of:" : "What word matches this definition?",
                systemImage: "questionmark.circle"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            
            // The word or definition
            if quizMode == .multipleChoice {
                Text(question.word.word)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
            } else {
                Text(question.word.definition)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    /// Multiple choice answer options.
    private func multipleChoiceAnswers(_ question: QuizQuestion) -> some View {
        VStack(spacing: 12) {
            ForEach(question.options, id: \.self) { option in
                Button {
                    selectAnswer(option, for: question)
                } label: {
                    HStack {
                        Text(option)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Show checkmark/x after answering
                        if showingFeedback {
                            if option == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if option == selectedAnswer && option != question.correctAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        } else if option == selectedAnswer {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(.blue)
                                .font(.caption)
                        } else {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(answerBackground(for: option, question: question))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(showingFeedback)
            }
        }
    }
    
    /// Fill-in-the-blank answer input.
    private func fillInBlankAnswer(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            TextField("Type your answer...", text: $userInput)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .disabled(showingFeedback)
            
            if !showingFeedback {
                Button {
                    submitFillInBlank(for: question)
                } label: {
                    Text("Submit Answer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(.borderedProminent)
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    /// Feedback card shown after answering.
    private func feedbackCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            // Correct/Incorrect indicator
            HStack {
                Image(systemName: question.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(question.isCorrect == true ? .green : .red)
                
                Text(question.isCorrect == true ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .foregroundStyle(question.isCorrect == true ? .green : .red)
            }
            
            // Show correct answer if wrong
            if question.isCorrect != true {
                VStack(spacing: 8) {
                    Text("The correct answer was:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if quizMode == .multipleChoice {
                        Text(question.correctAnswer)
                            .font(.body)
                            .fontWeight(.medium)
                    } else {
                        Text(question.word.word)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // Example sentence for context
            if !question.word.exampleSentence.isEmpty {
                VStack(spacing: 4) {
                    Text("Example:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\"\(question.word.exampleSentence)\"")
                        .font(.callout)
                        .italic()
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(question.isCorrect == true ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
    
    /// Next question button.
    private var nextButton: some View {
        Button {
            goToNextQuestion()
        } label: {
            Text(studyVM.hasMoreQuestions ? "Next Question" : "Finish Quiz")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .background(Color(.systemBackground))
    }
    
    /// Returns the background color for an answer option.
    private func answerBackground(for option: String, question: QuizQuestion) -> Color {
        if showingFeedback {
            if option == question.correctAnswer {
                return Color.green.opacity(0.2)
            } else if option == selectedAnswer {
                return Color.red.opacity(0.2)
            }
        } else if option == selectedAnswer {
            return Color.blue.opacity(0.1)
        }
        return Color(.systemBackground)
    }
    
    // MARK: - Actions
    
    /// Starts the quiz session.
    private func startQuiz() {
        studyVM.vocabViewModel = vocabViewModel
        
        let words = studyVM.getWords(for: source, from: vocabViewModel)
        
        if words.count >= 4 {
            studyVM.startQuizSession(with: words, source: source, mode: quizMode)
        }
    }
    
    /// Selects an answer for multiple choice.
    private func selectAnswer(_ answer: String, for question: QuizQuestion) {
        logger.debug("❓ Selected answer: '\(answer)' for '\(question.word.word)'")
        
        selectedAnswer = answer
        studyVM.submitAnswer(answer)
        
        withAnimation(.spring(response: 0.3)) {
            showingFeedback = true
        }
    }
    
    /// Submits the fill-in-the-blank answer.
    private func submitFillInBlank(for question: QuizQuestion) {
        let answer = userInput.trimmingCharacters(in: .whitespaces)
        logger.debug("❓ Submitted fill-in answer: '\(answer)' for definition")
        
        studyVM.submitAnswer(answer)
        
        withAnimation(.spring(response: 0.3)) {
            showingFeedback = true
        }
    }
    
    /// Moves to the next question.
    private func goToNextQuestion() {
        withAnimation {
            showingFeedback = false
            selectedAnswer = nil
            userInput = ""
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            studyVM.nextQuestion()
        }
    }
}

// MARK: - Quiz Complete View

/// View shown when a quiz is complete.
struct QuizCompleteView: View {
    
    let result: StudySessionResult?
    let questions: [QuizQuestion]
    let onDismiss: () -> Void
    
    @State private var showingReview = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Score display
                scoreDisplay
                
                // Performance message
                performanceMessage
                
                // Stats summary
                if let result = result {
                    statsSummary(result)
                }
                
                // Action buttons
                actionButtons
                
                // Review incorrect answers
                if questions.contains(where: { $0.isCorrect == false }) {
                    reviewSection
                }
            }
            .padding()
        }
    }
    
    /// Main score display.
    private var scoreDisplay: some View {
        VStack(spacing: 8) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result?.scorePercentage ?? 0) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.8), value: result?.scorePercentage)
                
                VStack(spacing: 4) {
                    Text("\(result?.scorePercentage ?? 0)%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    
                    Text("\(result?.correctAnswers ?? 0)/\(result?.totalQuestions ?? 0)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 180, height: 180)
        }
    }
    
    /// Performance message based on score.
    private var performanceMessage: some View {
        VStack(spacing: 8) {
            Text(messageTitle)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(messageSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// Stats summary cards.
    private func statsSummary(_ result: StudySessionResult) -> some View {
        HStack(spacing: 16) {
            QuizStatCard(
                icon: "clock.fill",
                value: result.formattedDuration,
                label: "Time",
                color: .purple
            )
            
            QuizStatCard(
                icon: "checkmark.circle.fill",
                value: "\(result.correctAnswers)",
                label: "Correct",
                color: .green
            )
            
            QuizStatCard(
                icon: "xmark.circle.fill",
                value: "\(result.totalQuestions - result.correctAnswers)",
                label: "Incorrect",
                color: .red
            )
        }
    }
    
    /// Action buttons.
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    /// Review section for incorrect answers.
    private var reviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showingReview.toggle()
                }
            } label: {
                HStack {
                    Text("Review Incorrect Answers")
                        .font(.headline)
                    Spacer()
                    Image(systemName: showingReview ? "chevron.up" : "chevron.down")
                }
                .foregroundStyle(.primary)
            }
            
            if showingReview {
                ForEach(questions.filter { $0.isCorrect == false }) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(question.word.word)
                            .font(.headline)
                        
                        Text(question.word.definition)
                            .font(.body)
                            .foregroundStyle(.secondary)
                        
                        if let userAnswer = question.userAnswer {
                            HStack {
                                Text("Your answer:")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Text(userAnswer)
                                    .font(.caption)
                                    .strikethrough()
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Computed Properties
    
    private var scoreColor: Color {
        guard let percentage = result?.scorePercentage else { return .gray }
        if percentage >= 80 { return .green }
        if percentage >= 60 { return .orange }
        return .red
    }
    
    private var messageTitle: String {
        guard let percentage = result?.scorePercentage else { return "Quiz Complete!" }
        if percentage >= 90 { return "Outstanding! 🌟" }
        if percentage >= 80 { return "Great Job! 🎉" }
        if percentage >= 70 { return "Good Work! 👍" }
        if percentage >= 60 { return "Keep Practicing! 📚" }
        return "Review & Try Again! 💪"
    }
    
    private var messageSubtitle: String {
        guard let percentage = result?.scorePercentage else { return "" }
        if percentage >= 90 { return "You really know your vocabulary!" }
        if percentage >= 80 { return "You're doing great with these words!" }
        if percentage >= 70 { return "You're making solid progress!" }
        if percentage >= 60 { return "A little more practice and you'll master these!" }
        return "Review the words you missed and try again!"
    }
}

// MARK: - Stat Card

/// A stat card for quiz results.
struct QuizStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview

#Preview {
    QuizSessionView(source: .allWords, quizMode: .multipleChoice)
        .environmentObject(VocabViewModel())
}


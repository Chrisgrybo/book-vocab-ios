//
//  QuizView.swift
//  BookVocab
//
//  Premium quiz study mode with multiple choice and fill-in-blank.
//  Beautiful feedback animations and score tracking.
//
//  Features:
//  - Multiple choice questions
//  - Fill-in-the-blank questions
//  - Animated feedback
//  - Score summary
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "QuizView")

struct QuizSessionView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @EnvironmentObject var session: UserSessionViewModel
    @StateObject private var studyVM = StudyViewModel()
    
    // MARK: - Properties
    
    let source: StudySource
    let quizMode: StudyMode
    
    // MARK: - State
    
    @State private var showingExitConfirmation = false
    @State private var selectedAnswer: String? = nil
    @State private var showingFeedback = false
    @State private var userInput = ""
    @State private var hasAppeared = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppColors.groupedBackground
                    .ignoresSafeArea()
                
                Group {
                    if studyVM.showSessionComplete {
                        QuizCompleteContentView(
                            result: studyVM.lastSessionResult,
                            questions: studyVM.quizQuestions,
                            onDismiss: { dismiss() },
                            studyVM: studyVM
                        )
                    } else if studyVM.quizQuestions.isEmpty {
                        emptyStateView
                    } else {
                        quizContent
                    }
                }
            }
            .navigationTitle(quizMode == .multipleChoice ? "Quiz" : "Fill in Blank")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if studyVM.isSessionActive {
                            showingExitConfirmation = true
                        } else {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
            .confirmationDialog("Exit Quiz?", isPresented: $showingExitConfirmation) {
                Button("Exit", role: .destructive) {
                    studyVM.endSession()
                    dismiss()
                }
                Button("Continue", role: .cancel) { }
            } message: {
                Text("You've answered \(studyVM.currentQuestionIndex) of \(studyVM.quizQuestions.count) questions.")
            }
            .onAppear {
                // Set user ID for saving study sessions to Supabase
                if let userId = session.currentUser?.id {
                    studyVM.setUserId(userId)
                }
                
                startQuiz()
                withAnimation(AppAnimation.spring.delay(0.1)) {
                    hasAppeared = true
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.xl) {
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("Not Enough Words")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("You need at least 4 words to take a quiz.\nAdd more vocabulary first!")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                dismiss()
            } label: {
                Text("Go Back")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, AppSpacing.xxxl)
        }
        .padding(AppSpacing.xl)
    }
    
    // MARK: - Quiz Content
    
    private var quizContent: some View {
        VStack(spacing: 0) {
            // Progress header
            quizProgressHeader
            
            // Question
            if let question = studyVM.currentQuestion {
                ScrollView {
                    VStack(spacing: AppSpacing.lg) {
                        questionCard(question)
                            .padding(.top, AppSpacing.lg)
                        
                        if quizMode == .multipleChoice {
                            multipleChoiceOptions(question)
                        } else {
                            fillInBlankInput(question)
                        }
                        
                        if showingFeedback {
                            feedbackCard(question)
                        }
                    }
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                    .padding(.bottom, 100)
                }
                
                // Next button
                if showingFeedback {
                    nextButton
                }
            }
        }
    }
    
    // MARK: - Progress Header
    
    private var quizProgressHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                    
                    Capsule()
                        .fill(AppColors.purpleGradient)
                        .frame(width: geo.size.width * studyVM.quizProgress)
                        .animation(AppAnimation.smooth, value: studyVM.quizProgress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, AppSpacing.horizontalPadding)
            
            // Stats row
            HStack {
                Text(studyVM.quizProgressText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                    Text("\(studyVM.correctAnswersCount)")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
        }
        .padding(.vertical, AppSpacing.md)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Question Card
    
    private func questionCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Label
            Text(quizMode == .multipleChoice ? "What is the definition of:" : "What word matches this definition?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // Content
            if quizMode == .multipleChoice {
                Text(question.word.word)
                    .font(.system(size: 32, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
            } else {
                Text(question.word.definition)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(AppSpacing.xl)
        .frame(maxWidth: .infinity)
        .cardStyle()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Multiple Choice Options
    
    private func multipleChoiceOptions(_ question: QuizQuestion) -> some View {
        VStack(spacing: AppSpacing.sm) {
            ForEach(Array(question.options.enumerated()), id: \.offset) { index, option in
                Button {
                    selectAnswer(option, for: question)
                } label: {
                    HStack(spacing: AppSpacing.md) {
                        // Option letter
                        Text(String(Character(UnicodeScalar(65 + index)!)))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(optionLetterColor(for: option, question: question))
                            .frame(width: 28, height: 28)
                            .background(optionLetterBackground(for: option, question: question))
                            .clipShape(Circle())
                        
                        // Option text
                        Text(option)
                            .font(.body)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        // Result indicator
                        if showingFeedback {
                            if option == question.correctAnswer {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.success)
                            } else if option == selectedAnswer {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AppColors.error)
                            }
                        }
                    }
                    .padding(AppSpacing.md)
                    .background(optionBackground(for: option, question: question))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .stroke(optionBorder(for: option, question: question), lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .disabled(showingFeedback)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 20)
                .animation(AppAnimation.spring.delay(Double(index) * 0.05), value: hasAppeared)
            }
        }
    }
    
    // MARK: - Fill in Blank Input
    
    private func fillInBlankInput(_ question: QuizQuestion) -> some View {
        VStack(spacing: AppSpacing.md) {
            TextField("Type your answer...", text: $userInput)
                .font(.title3)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .textFieldStyle(.plain)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .disabled(showingFeedback)
            
            if !showingFeedback {
                Button {
                    submitFillInBlank(for: question)
                } label: {
                    Text("Submit")
                }
                .buttonStyle(.primary)
                .disabled(userInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Feedback Card
    
    private func feedbackCard(_ question: QuizQuestion) -> some View {
        VStack(spacing: AppSpacing.md) {
            // Result indicator
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: question.isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(question.isCorrect == true ? AppColors.success : AppColors.error)
                
                Text(question.isCorrect == true ? "Correct!" : "Incorrect")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(question.isCorrect == true ? AppColors.success : AppColors.error)
            }
            
            // Show correct answer if wrong
            if question.isCorrect != true {
                VStack(spacing: AppSpacing.xs) {
                    Text("The correct answer was:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(quizMode == .multipleChoice ? question.correctAnswer : question.word.word)
                        .font(.body)
                        .fontWeight(.semibold)
                }
                .padding(.top, AppSpacing.xs)
            }
            
            // Example
            if !question.word.exampleSentence.isEmpty {
                VStack(spacing: AppSpacing.xxs) {
                    Text("Example:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\"\(question.word.exampleSentence)\"")
                        .font(.subheadline)
                        .italic()
                        .multilineTextAlignment(.center)
                }
                .padding(.top, AppSpacing.sm)
            }
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .fill(question.isCorrect == true ? AppColors.success.opacity(0.1) : AppColors.error.opacity(0.1))
        )
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
    
    // MARK: - Next Button
    
    private var nextButton: some View {
        Button {
            goToNextQuestion()
        } label: {
            Text(studyVM.hasMoreQuestions ? "Next Question" : "Finish Quiz")
        }
        .buttonStyle(.primary)
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .padding(.vertical, AppSpacing.md)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Option Styling Helpers
    
    private func optionLetterColor(for option: String, question: QuizQuestion) -> Color {
        if showingFeedback {
            if option == question.correctAnswer { return .white }
            if option == selectedAnswer { return .white }
        }
        if option == selectedAnswer { return .white }
        return .primary
    }
    
    private func optionLetterBackground(for option: String, question: QuizQuestion) -> Color {
        if showingFeedback {
            if option == question.correctAnswer { return AppColors.success }
            if option == selectedAnswer { return AppColors.error }
        }
        if option == selectedAnswer { return Color.accentColor }
        return Color.gray.opacity(0.15)
    }
    
    private func optionBackground(for option: String, question: QuizQuestion) -> Color {
        if showingFeedback {
            if option == question.correctAnswer { return AppColors.success.opacity(0.1) }
            if option == selectedAnswer { return AppColors.error.opacity(0.1) }
        }
        return AppColors.cardBackground
    }
    
    private func optionBorder(for option: String, question: QuizQuestion) -> Color {
        if showingFeedback {
            if option == question.correctAnswer { return AppColors.success }
            if option == selectedAnswer { return AppColors.error }
        }
        if option == selectedAnswer { return Color.accentColor }
        return Color.clear
    }
    
    // MARK: - Actions
    
    private func startQuiz() {
        studyVM.vocabViewModel = vocabViewModel
        
        // Preload an interstitial ad for when the quiz ends
        AdManager.shared.preloadInterstitialIfNeeded()
        
        let words = studyVM.getWords(for: source, from: vocabViewModel)
        
        if words.count >= 4 {
            studyVM.startQuizSession(with: words, source: source, mode: quizMode)
        }
    }
    
    private func selectAnswer(_ answer: String, for question: QuizQuestion) {
        logger.debug("❓ Selected: '\(answer)'")
        
        selectedAnswer = answer
        studyVM.submitAnswer(answer)
        
        withAnimation(AppAnimation.spring) {
            showingFeedback = true
        }
    }
    
    private func submitFillInBlank(for question: QuizQuestion) {
        let answer = userInput.trimmingCharacters(in: .whitespaces)
        logger.debug("❓ Submitted: '\(answer)'")
        
        studyVM.submitAnswer(answer)
        
        withAnimation(AppAnimation.spring) {
            showingFeedback = true
        }
    }
    
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

// MARK: - Quiz Complete Content View

struct QuizCompleteContentView: View {
    let result: StudySessionResult?
    let questions: [QuizQuestion]
    let onDismiss: () -> Void
    
    /// Reference to the StudyViewModel for marking words as mastered
    @ObservedObject var studyVM: StudyViewModel
    
    /// Reference to VocabViewModel for persisting mastery status
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    /// Set of word IDs the user has selected to mark as mastered
    @State private var selectedForMastery: Set<UUID> = []
    
    /// Whether mastery selections have been saved
    @State private var hasSaved = false
    
    /// Whether save operation is in progress
    @State private var isSaving = false
    
    @State private var hasAppeared = false
    @State private var hasTriggeredAd = false
    
    /// Premium status for ad display
    @AppStorage("isPremium") private var isPremium: Bool = false
    
    // MARK: - Computed Properties
    
    private var scoreColor: Color {
        guard let p = result?.scorePercentage else { return .gray }
        if p >= 80 { return AppColors.success }
        if p >= 60 { return AppColors.warning }
        return AppColors.error
    }
    
    private var messageTitle: String {
        guard let p = result?.scorePercentage else { return "Quiz Complete!" }
        if p >= 90 { return "Outstanding! 🌟" }
        if p >= 80 { return "Great Job! 🎉" }
        if p >= 70 { return "Good Work! 👍" }
        if p >= 60 { return "Keep Practicing! 📚" }
        return "Review & Try Again! 💪"
    }
    
    /// Words that can be marked as mastered (not already mastered)
    private var masterableWords: [QuizQuestion] {
        questions.filter { !$0.word.mastered }
    }
    
    /// Count of words selected for mastery
    private var selectedCount: Int {
        selectedForMastery.count
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Score header
                scoreHeader
                    .padding(.top, AppSpacing.lg)
                
                // Stats row
                statsRow
                
                // Word summary section
                wordSummarySection
                
                // Save and Done buttons
                actionButtons
                
                Spacer(minLength: AppSpacing.xxxl)
            }
        }
        .onAppear {
            logger.debug("🎬 QuizCompleteContentView appeared")
            
            // Pre-select words that were answered correctly for convenience
            for question in questions where question.isCorrect == true && !question.word.mastered {
                selectedForMastery.insert(question.word.id)
            }
            
            withAnimation(AppAnimation.bouncy.delay(0.1)) {
                hasAppeared = true
            }
            
            // NOTE: Ad is now shown AFTER user taps Save, not on appear
        }
    }
    
    // MARK: - Score Header
    
    private var scoreHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Score circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: CGFloat(result?.scorePercentage ?? 0) / 100)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(AppAnimation.smooth.delay(0.2), value: hasAppeared)
                
                VStack(spacing: 4) {
                    Text("\(result?.scorePercentage ?? 0)%")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(scoreColor)
                    
                    Text("\(result?.correctAnswers ?? 0)/\(result?.totalQuestions ?? 0)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 150, height: 150)
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            
            // Message
            Text(messageTitle)
                .font(.title3)
                .fontWeight(.bold)
                .opacity(hasAppeared ? 1 : 0)
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: AppSpacing.md) {
            if let result = result {
                QuizResultStat(icon: "clock.fill", value: result.formattedDuration, label: "Time", color: .purple)
                QuizResultStat(icon: "checkmark.circle.fill", value: "\(result.correctAnswers)", label: "Correct", color: AppColors.success)
                QuizResultStat(icon: "xmark.circle.fill", value: "\(result.totalQuestions - result.correctAnswers)", label: "Wrong", color: AppColors.error)
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .opacity(hasAppeared ? 1 : 0)
    }
    
    // MARK: - Word Summary Section
    
    private var wordSummarySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Section header
            HStack {
                Text("Words Reviewed")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !masterableWords.isEmpty && !hasSaved {
                    Button {
                        // Select all unmastered words
                        withAnimation(AppAnimation.quick) {
                            if selectedForMastery.count == masterableWords.count {
                                selectedForMastery.removeAll()
                            } else {
                                for q in masterableWords {
                                    selectedForMastery.insert(q.word.id)
                                }
                            }
                        }
                    } label: {
                        Text(selectedForMastery.count == masterableWords.count ? "Deselect All" : "Select All")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.primary)
                    }
                }
            }
            
            // Info text
            if !hasSaved && !masterableWords.isEmpty {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                    Text("Select words to mark as mastered")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            // Word list
            VStack(spacing: AppSpacing.sm) {
                ForEach(questions) { question in
                    WordSummaryRow(
                        question: question,
                        isSelected: selectedForMastery.contains(question.word.id),
                        hasSaved: hasSaved,
                        onToggle: {
                            toggleSelection(for: question.word.id)
                        }
                    )
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .padding(.horizontal, AppSpacing.horizontalPadding)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            // Save button (only if there are words to save)
            if !hasSaved && !selectedForMastery.isEmpty {
                Button {
                    saveSelections()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Mark \(selectedCount) Word\(selectedCount == 1 ? "" : "s") as Mastered")
                        }
                    }
                }
                .buttonStyle(.primary)
                .disabled(isSaving)
            }
            
            // Saved confirmation
            if hasSaved && selectedCount > 0 {
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                    Text("\(selectedCount) word\(selectedCount == 1 ? "" : "s") marked as mastered!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.success)
                }
                .padding(AppSpacing.md)
                .frame(maxWidth: .infinity)
                .background(AppColors.success.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Done button
            if hasSaved || selectedForMastery.isEmpty {
                Button(action: onDismiss) {
                    Text("Done")
                }
                .buttonStyle(.primary)
            } else {
                Button(action: onDismiss) {
                    Text("Done")
                }
                .buttonStyle(.secondary)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .opacity(hasAppeared ? 1 : 0)
    }
    
    // MARK: - Actions
    
    /// Toggles selection of a word for mastery
    private func toggleSelection(for wordId: UUID) {
        guard !hasSaved else { return }
        
        // Don't allow toggling already mastered words
        guard let question = questions.first(where: { $0.word.id == wordId }),
              !question.word.mastered else { return }
        
        withAnimation(AppAnimation.quick) {
            if selectedForMastery.contains(wordId) {
                selectedForMastery.remove(wordId)
            } else {
                selectedForMastery.insert(wordId)
            }
        }
    }
    
    /// Saves the selected words as mastered, then shows interstitial ad
    private func saveSelections() {
        guard !selectedForMastery.isEmpty else { return }
        
        isSaving = true
        let wordsToSave = selectedForMastery
        logger.info("💾 Saving \(wordsToSave.count) words as mastered from quiz")
        
        Task {
            // Update mastered status via StudyViewModel
            // This updates both the local allWords array AND the cache
            await studyVM.markWordsAsMasteredFromSummary(wordIds: wordsToSave)
            
            // NOTE: We intentionally do NOT call fetchAllWords() here
            // The mastered status has already been updated in:
            // 1. VocabViewModel.allWords (in-memory)
            // 2. CacheService (Core Data)
            // Calling fetchAllWords() could cause race conditions or data issues
            
            logger.info("💾 Save operation completed for \(wordsToSave.count) words")
            
            await MainActor.run {
                withAnimation(AppAnimation.spring) {
                    isSaving = false
                    hasSaved = true
                }
                logger.info("✅ Mastery selections saved successfully - UI updated")
                
                // Show interstitial ad AFTER saving is complete
                showInterstitialAdAfterSave()
            }
        }
    }
    
    /// Shows an interstitial ad after the user saves their mastery selections.
    /// When ad is dismissed (or skipped), the view dismisses and returns to study tab.
    private func showInterstitialAdAfterSave() {
        guard !hasTriggeredAd else {
            logger.debug("🎯 Ad already triggered for this quiz, skipping")
            return
        }
        
        guard !isPremium else {
            logger.debug("🎯 Premium user - no interstitial ad")
            return
        }
        
        hasTriggeredAd = true
        logger.info("🎯 Showing interstitial ad after save...")
        
        // Capture onDismiss closure before async work
        let dismissAction = onDismiss
        
        // Small delay to let user see the "saved" confirmation
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay
            
            logger.info("🎯 Delay complete, attempting to show interstitial...")
            
            if let viewController = AdManager.shared.getRootViewController() {
                logger.info("🎯 Got view controller, showing ad...")
                AdManager.shared.showInterstitial(from: viewController) {
                    logger.info("🎯 Interstitial ad dismissed, returning to study tab")
                    // Use captured dismiss action to avoid [self] capture issues
                    dismissAction()
                }
            } else {
                logger.warning("⚠️ Could not get root view controller for ad presentation")
                // Still dismiss the view even if ad couldn't be shown
                dismissAction()
            }
        }
    }
}

// MARK: - Word Summary Row

/// A row displaying a single word's quiz result with optional mastery toggle.
struct WordSummaryRow: View {
    let question: QuizQuestion
    let isSelected: Bool
    let hasSaved: Bool
    let onToggle: () -> Void
    
    /// Whether this word can be toggled for mastery
    private var canToggle: Bool {
        !question.word.mastered && !hasSaved
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Result indicator
            ZStack {
                Circle()
                    .fill(question.isCorrect == true ? AppColors.success.opacity(0.15) : AppColors.error.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: question.isCorrect == true ? "checkmark" : "xmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(question.isCorrect == true ? AppColors.success : AppColors.error)
            }
            
            // Word info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(question.word.word)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Already mastered badge
                    if question.word.mastered {
                        HStack(spacing: 2) {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Mastered")
                        }
                        .font(.caption2)
                        .foregroundStyle(AppColors.success)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(AppColors.success.opacity(0.15))
                        .clipShape(Capsule())
                    }
                }
                
                Text(question.word.definition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Mastery toggle (only for non-mastered words)
            if !question.word.mastered {
                Button(action: onToggle) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isSelected ? AppColors.success : Color.clear)
                            .frame(width: 24, height: 24)
                        
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(isSelected ? AppColors.success : Color.gray.opacity(0.4), lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!canToggle)
                .opacity(canToggle ? 1 : 0.5)
                .animation(AppAnimation.quick, value: isSelected)
            }
        }
        .padding(AppSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .fill(isSelected && !hasSaved ? AppColors.success.opacity(0.05) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                .stroke(isSelected && !hasSaved ? AppColors.success.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

struct QuizResultStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
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
    }
}

// MARK: - Preview

#Preview {
    QuizSessionView(source: .allWords, quizMode: .multipleChoice)
        .environmentObject(VocabViewModel())
}

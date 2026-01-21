//
//  FlashcardView.swift
//  BookVocab
//
//  Premium flashcard study mode with beautiful animations.
//  Delightful 3D flip effect and swipe gestures.
//
//  Features:
//  - 3D flip animation
//  - Swipe right to master, left to skip
//  - Progress tracking
//  - Session summary
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "FlashcardView")

struct FlashcardSessionView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @EnvironmentObject var session: UserSessionViewModel
    @StateObject private var studyVM = StudyViewModel()
    
    // MARK: - Properties
    
    let source: StudySource
    let learningOnly: Bool
    
    // MARK: - State
    
    @State private var showingExitConfirmation = false
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
                        FlashcardCompleteContentView(
                            result: studyVM.lastSessionResult,
                            studyVM: studyVM,
                            onDismiss: { dismiss() }
                        )
                    } else if studyVM.studyWords.isEmpty {
                        emptyStateView
                    } else {
                        flashcardContent
                    }
                }
            }
            .navigationTitle("Flashcards")
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
            .confirmationDialog("Exit Study Session?", isPresented: $showingExitConfirmation) {
                Button("Exit", role: .destructive) {
                    studyVM.endSession()
                    dismiss()
                }
                Button("Continue", role: .cancel) { }
            } message: {
                Text("You've reviewed \(studyVM.currentIndex + 1) of \(studyVM.studyWords.count) words.")
            }
            .onAppear {
                // Set user ID for saving study sessions to Supabase
                if let userId = session.currentUser?.id {
                    studyVM.setUserId(userId)
                }
                
                startSession()
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
                
                Image(systemName: "rectangle.on.rectangle.slash")
                    .font(.system(size: 48))
                    .foregroundStyle(AppColors.primary)
            }
            
            VStack(spacing: AppSpacing.sm) {
                Text("No Words to Study")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Add some vocabulary words first,\nthen come back to study!")
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
    
    // MARK: - Flashcard Content
    
    private var flashcardContent: some View {
        VStack(spacing: 0) {
            // Progress header
            progressHeader
            
            Spacer()
            
            // Flashcard
            if let word = studyVM.currentWord {
                FlashcardCardView(
                    word: word,
                    isFlipped: studyVM.isFlipped,
                    onTap: { studyVM.flipCard() },
                    onSwipeLeft: { studyVM.skipCurrentWord() },
                    onSwipeRight: { studyVM.markCurrentAsMastered() }
                )
                .padding(.horizontal, AppSpacing.xl)
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 30)
            }
            
            Spacer()
            
            // Hint
            Text(studyVM.isFlipped ? "Swipe or use buttons below" : "Tap to reveal")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .padding(.bottom, AppSpacing.md)
            
            // Control buttons
            controlButtons
        }
    }
    
    // MARK: - Progress Header
    
    private var progressHeader: some View {
        VStack(spacing: AppSpacing.sm) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                    
                    Capsule()
                        .fill(AppColors.primary)
                        .frame(width: geo.size.width * studyVM.sessionProgress)
                        .animation(AppAnimation.smooth, value: studyVM.sessionProgress)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, AppSpacing.horizontalPadding)
            
            // Stats row
            HStack {
                Text(studyVM.progressText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.success)
                    Text("\(studyVM.sessionMasteredWords.count)")
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
    
    // MARK: - Control Buttons
    
    private var controlButtons: some View {
        HStack(spacing: AppSpacing.xl) {
            // Skip
            ControlButton(
                icon: "xmark",
                label: "Skip",
                color: AppColors.warning
            ) {
                withAnimation(AppAnimation.spring) {
                    studyVM.skipCurrentWord()
                }
            }
            
            // Flip
            ControlButton(
                icon: "arrow.triangle.2.circlepath",
                label: "Flip",
                color: .blue,
                isLarge: true
            ) {
                withAnimation(AppAnimation.spring) {
                    studyVM.flipCard()
                }
            }
            
            // Mastered
            ControlButton(
                icon: "checkmark",
                label: "Got it",
                color: AppColors.success
            ) {
                withAnimation(AppAnimation.spring) {
                    studyVM.markCurrentAsMastered()
                }
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .padding(.horizontal, AppSpacing.xl)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Actions
    
    private func startSession() {
        studyVM.vocabViewModel = vocabViewModel
        
        // Preload an interstitial ad for when the session ends
        AdManager.shared.preloadInterstitialIfNeeded()
        
        let words: [VocabWord]
        if learningOnly {
            words = studyVM.getLearningWords(for: source, from: vocabViewModel)
        } else {
            words = studyVM.getWords(for: source, from: vocabViewModel)
        }
        
        if !words.isEmpty {
            studyVM.startFlashcardSession(with: words, source: source)
        }
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let color: Color
    var isLarge: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: isLarge ? 64 : 52, height: isLarge ? 64 : 52)
                    
                    Image(systemName: icon)
                        .font(isLarge ? .title2 : .body)
                        .fontWeight(.semibold)
                        .foregroundStyle(color)
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(AppAnimation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Flashcard Card View

struct FlashcardCardView: View {
    let word: VocabWord
    let isFlipped: Bool
    let onTap: () -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    private var swipeProgress: Double {
        Double(offset.width) / 150.0
    }
    
    var body: some View {
        ZStack {
            // Back (definition)
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            
            // Front (word)
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .frame(height: 420)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 25)
                }
                .onEnded { gesture in
                    handleSwipe(gesture)
                }
        )
        .onTapGesture {
            withAnimation(AppAnimation.spring) {
                onTap()
            }
        }
        .animation(AppAnimation.spring, value: offset)
        .animation(AppAnimation.spring, value: isFlipped)
        // Swipe indicator overlays
        .overlay(alignment: .topLeading) {
            if swipeProgress < -0.3 {
                skipIndicator
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .topTrailing) {
            if swipeProgress > 0.3 {
                masteredIndicator
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Card Front
    
    private var cardFront: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            // Word
            Text(word.word)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
            
            // Mastered badge
            if word.mastered {
                HStack(spacing: AppSpacing.xxs) {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Mastered")
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.success)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.success.opacity(0.15))
                .clipShape(Capsule())
            }
            
            Spacer()
            
            // Tap hint
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "hand.tap.fill")
                Text("Tap to reveal")
            }
            .font(.subheadline)
            .foregroundStyle(.tertiary)
            .padding(.bottom, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.5), Color.white.opacity(0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
    
    // MARK: - Card Back
    
    private var cardBack: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                HStack {
                    Text(word.word)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if word.mastered {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(AppColors.success)
                    }
                }
                
                Divider()
                
                // Definition
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Label("Definition", systemImage: "text.book.closed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(word.definition)
                        .font(.body)
                }
                
                // Example
                if !word.exampleSentence.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Example", systemImage: "text.quote")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(word.exampleSentence)\"")
                            .font(.body)
                            .italic()
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Synonyms
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Synonyms", systemImage: "equal.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        FlowLayoutSimple(items: word.synonyms, color: .blue)
                    }
                }
                
                // Antonyms
                if !word.antonyms.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Label("Antonyms", systemImage: "arrow.left.arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        FlowLayoutSimple(items: word.antonyms, color: .orange)
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                .fill(AppColors.cardBackground)
                .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.extraLarge, style: .continuous)
                .stroke(AppColors.success.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Indicators
    
    private var skipIndicator: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "xmark")
            Text("Skip")
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.warning)
        .clipShape(Capsule())
        .padding(AppSpacing.md)
    }
    
    private var masteredIndicator: some View {
        HStack(spacing: AppSpacing.xxs) {
            Image(systemName: "checkmark")
            Text("Got it!")
        }
        .font(.caption)
        .fontWeight(.bold)
        .foregroundStyle(.white)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.success)
        .clipShape(Capsule())
        .padding(AppSpacing.md)
    }
    
    // MARK: - Swipe Handling
    
    private func handleSwipe(_ gesture: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        if gesture.translation.width > threshold {
            logger.debug("🎴 Swiped right - mastered")
            withAnimation(AppAnimation.spring) {
                offset = CGSize(width: 500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onSwipeRight()
                offset = .zero
                rotation = 0
            }
        } else if gesture.translation.width < -threshold {
            logger.debug("🎴 Swiped left - skip")
            withAnimation(AppAnimation.spring) {
                offset = CGSize(width: -500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                onSwipeLeft()
                offset = .zero
                rotation = 0
            }
        } else {
            withAnimation(AppAnimation.spring) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - Flow Layout Simple

struct FlowLayoutSimple: View {
    let items: [String]
    let color: Color
    
    var body: some View {
        // Simple horizontal scroll for pills
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(color.opacity(0.12))
                        .foregroundStyle(color)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Flashcard Complete Content View

struct FlashcardCompleteContentView: View {
    let result: StudySessionResult?
    
    /// Reference to the StudyViewModel for marking words as mastered
    @ObservedObject var studyVM: StudyViewModel
    
    let onDismiss: () -> Void
    
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
    
    /// Words studied in this session with their "got it" status
    private var sessionWords: [(word: VocabWord, gotIt: Bool)] {
        studyVM.getFlashcardSessionWords()
    }
    
    /// Words that can be marked as mastered (not already mastered)
    private var masterableWords: [VocabWord] {
        sessionWords.filter { !$0.word.mastered }.map { $0.word }
    }
    
    /// Count of words selected for mastery
    private var selectedCount: Int {
        selectedForMastery.count
    }
    
    /// Count of words user marked as "got it"
    private var gotItCount: Int {
        sessionWords.filter { $0.gotIt }.count
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppSpacing.lg) {
                // Celebration header
                celebrationHeader
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
            logger.debug("🎬 FlashcardCompleteContentView appeared")
            
            // Pre-select words that user marked as "got it" for convenience
            for (word, gotIt) in sessionWords where gotIt && !word.mastered {
                selectedForMastery.insert(word.id)
            }
            
            withAnimation(AppAnimation.bouncy.delay(0.1)) {
                hasAppeared = true
            }
            
            // NOTE: Ad is now shown AFTER user taps Save, not on appear
        }
    }
    
    // MARK: - Celebration Header
    
    private var celebrationHeader: some View {
        VStack(spacing: AppSpacing.md) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(AppColors.tanDark.opacity(0.5))
                    .frame(width: 100, height: 100)
                    .scaleEffect(hasAppeared ? 1 : 0.5)
                    .opacity(hasAppeared ? 1 : 0)
                
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.warning)
                    .scaleEffect(hasAppeared ? 1 : 0)
            }
            
            VStack(spacing: AppSpacing.xs) {
                Text("Session Complete!")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Great job studying!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .opacity(hasAppeared ? 1 : 0)
        }
    }
    
    // MARK: - Stats Row
    
    private var statsRow: some View {
        HStack(spacing: AppSpacing.md) {
            if let result = result {
                CompletionStat(value: "\(result.totalQuestions)", label: "Reviewed", color: .blue)
                CompletionStat(value: "\(gotItCount)", label: "Got It", color: AppColors.success)
                CompletionStat(value: result.formattedDuration, label: "Time", color: .purple)
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
                                for word in masterableWords {
                                    selectedForMastery.insert(word.id)
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
                ForEach(sessionWords, id: \.word.id) { item in
                    FlashcardWordSummaryRow(
                        word: item.word,
                        gotIt: item.gotIt,
                        isSelected: selectedForMastery.contains(item.word.id),
                        hasSaved: hasSaved,
                        onToggle: {
                            toggleSelection(for: item.word.id)
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
        guard let wordData = sessionWords.first(where: { $0.word.id == wordId }),
              !wordData.word.mastered else { return }
        
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
        logger.info("💾 Saving \(wordsToSave.count) words as mastered from flashcards")
        
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
            logger.debug("🎯 Ad already triggered for this session, skipping")
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

// MARK: - Flashcard Word Summary Row

/// A row displaying a single word's flashcard result with optional mastery toggle.
struct FlashcardWordSummaryRow: View {
    let word: VocabWord
    let gotIt: Bool
    let isSelected: Bool
    let hasSaved: Bool
    let onToggle: () -> Void
    
    /// Whether this word can be toggled for mastery
    private var canToggle: Bool {
        !word.mastered && !hasSaved
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            // Result indicator (Got it or Skipped)
            ZStack {
                Circle()
                    .fill(gotIt ? AppColors.success.opacity(0.15) : AppColors.warning.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: gotIt ? "checkmark" : "arrow.right")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(gotIt ? AppColors.success : AppColors.warning)
            }
            
            // Word info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: AppSpacing.xs) {
                    Text(word.word)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    // Already mastered badge
                    if word.mastered {
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
                    
                    // Got it / Skipped label
                    if !word.mastered {
                        Text(gotIt ? "Got it" : "Skipped")
                            .font(.caption2)
                            .foregroundStyle(gotIt ? AppColors.success : AppColors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background((gotIt ? AppColors.success : AppColors.warning).opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                
                Text(word.definition)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Mastery toggle (only for non-mastered words)
            if !word.mastered {
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

struct CompletionStat: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    FlashcardSessionView(source: .allWords, learningOnly: false)
        .environmentObject(VocabViewModel())
}

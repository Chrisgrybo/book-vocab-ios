//
//  FlashcardView.swift
//  BookVocab
//
//  Flashcard study mode with flip animations and swipe gestures.
//  Users can review words, flip to see definitions, and mark as mastered.
//
//  Features:
//  - Tap to flip cards with 3D animation
//  - Swipe right to mark as mastered
//  - Swipe left to skip
//  - Progress tracking
//  - Session completion summary
//

import SwiftUI
import os.log

/// Logger for FlashcardView debugging
private let logger = Logger(subsystem: "com.bookvocab.app", category: "FlashcardView")

// MARK: - Flashcard Session View

/// Main view for flashcard study sessions.
/// Manages the session flow and displays individual flashcards.
struct FlashcardSessionView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @StateObject private var studyVM = StudyViewModel()
    
    // MARK: - Properties
    
    /// The source of words for this session.
    let source: StudySource
    
    /// Whether to only show learning words (not mastered).
    let learningOnly: Bool
    
    // MARK: - State
    
    @State private var showingExitConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Group {
                if studyVM.showSessionComplete {
                    // Session complete view
                    SessionCompleteView(result: studyVM.lastSessionResult) {
                        dismiss()
                    }
                } else if studyVM.studyWords.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Main flashcard view
                    flashcardContent
                }
            }
            .navigationTitle("Flashcards")
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
            .confirmationDialog("Exit Study Session?", isPresented: $showingExitConfirmation) {
                Button("Exit", role: .destructive) {
                    studyVM.endSession()
                    dismiss()
                }
                Button("Continue Studying", role: .cancel) { }
            } message: {
                Text("Your progress will be saved. You've reviewed \(studyVM.currentIndex + 1) of \(studyVM.studyWords.count) words.")
            }
            .onAppear {
                startSession()
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state when no words available.
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Words to Study")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add some vocabulary words first, then come back to study!")
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
    
    /// Main flashcard content with card and controls.
    private var flashcardContent: some View {
        VStack(spacing: 0) {
            // Progress bar
            progressHeader
            
            Spacer()
            
            // Flashcard
            if let word = studyVM.currentWord {
                FlashcardCard(
                    word: word,
                    isFlipped: studyVM.isFlipped,
                    onTap: { studyVM.flipCard() },
                    onSwipeLeft: { studyVM.skipCurrentWord() },
                    onSwipeRight: { studyVM.markCurrentAsMastered() }
                )
                .padding(.horizontal, 24)
            }
            
            Spacer()
            
            // Hint text
            hintText
            
            // Control buttons
            controlButtons
        }
        .background(Color(.systemGroupedBackground))
    }
    
    /// Progress header showing session progress.
    private var progressHeader: some View {
        VStack(spacing: 8) {
            // Progress bar
            ProgressView(value: studyVM.sessionProgress)
                .tint(.blue)
                .padding(.horizontal)
            
            // Progress text
            HStack {
                Text(studyVM.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Mastered count
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("\(studyVM.sessionMasteredWords.count) mastered")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    /// Hint text below the card.
    private var hintText: some View {
        Text(studyVM.isFlipped ? "Swipe or tap buttons below" : "Tap card to flip")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.bottom, 8)
    }
    
    /// Control buttons for navigation.
    private var controlButtons: some View {
        HStack(spacing: 40) {
            // Skip button (swipe left alternative)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    studyVM.skipCurrentWord()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.left.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange)
                    Text("Skip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Flip button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    studyVM.flipCard()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                    Text("Flip")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Mastered button (swipe right alternative)
            Button {
                withAnimation(.spring(response: 0.3)) {
                    studyVM.markCurrentAsMastered()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("Mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Actions
    
    /// Starts the flashcard session.
    private func startSession() {
        studyVM.vocabViewModel = vocabViewModel
        
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

// MARK: - Flashcard Card

/// A single flashcard with flip animation and swipe gestures.
struct FlashcardCard: View {
    
    // MARK: - Properties
    
    let word: VocabWord
    let isFlipped: Bool
    let onTap: () -> Void
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    // MARK: - State
    
    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Back of card (definition)
            cardBack
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(
                    .degrees(isFlipped ? 0 : -180),
                    axis: (x: 0, y: 1, z: 0)
                )
            
            // Front of card (word)
            cardFront
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(
                    .degrees(isFlipped ? 180 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
        }
        .frame(height: 400)
        .offset(offset)
        .rotationEffect(.degrees(rotation))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    handleSwipe(gesture)
                }
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                onTap()
            }
        }
        .animation(.spring(response: 0.3), value: offset)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isFlipped)
    }
    
    // MARK: - Card Faces
    
    /// Front of the card showing the word.
    private var cardFront: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Text(word.word)
                .font(.system(size: 36, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)
            
            // Mastered badge if applicable
            if word.mastered {
                Label("Mastered", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Tap hint
            HStack(spacing: 4) {
                Image(systemName: "hand.tap")
                Text("Tap to see definition")
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }
    
    /// Back of the card showing definition and details.
    private var cardBack: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Word header
                HStack {
                    Text(word.word)
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    if word.mastered {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                Divider()
                
                // Definition
                VStack(alignment: .leading, spacing: 8) {
                    Label("Definition", systemImage: "text.book.closed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(word.definition)
                        .font(.body)
                }
                
                // Example sentence
                if !word.exampleSentence.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Example", systemImage: "text.quote")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("\"\(word.exampleSentence)\"")
                            .font(.body)
                            .italic()
                            .foregroundStyle(.primary.opacity(0.8))
                    }
                }
                
                // Synonyms
                if !word.synonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Synonyms", systemImage: "equal.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(word.synonyms, id: \.self) { synonym in
                                Text(synonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Antonyms
                if !word.antonyms.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Antonyms", systemImage: "arrow.left.arrow.right.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(word.antonyms, id: \.self) { antonym in
                                Text(antonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Gesture Handling
    
    /// Handles swipe gesture completion.
    private func handleSwipe(_ gesture: DragGesture.Value) {
        let threshold: CGFloat = 100
        
        if gesture.translation.width > threshold {
            // Swipe right - mark as mastered
            logger.debug("🎴 Swiped right on '\(word.word)' - marking as mastered")
            withAnimation(.spring(response: 0.3)) {
                offset = CGSize(width: 500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onSwipeRight()
                offset = .zero
                rotation = 0
            }
        } else if gesture.translation.width < -threshold {
            // Swipe left - skip
            logger.debug("🎴 Swiped left on '\(word.word)' - skipping")
            withAnimation(.spring(response: 0.3)) {
                offset = CGSize(width: -500, height: 0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                onSwipeLeft()
                offset = .zero
                rotation = 0
            }
        } else {
            // Return to center
            withAnimation(.spring(response: 0.3)) {
                offset = .zero
                rotation = 0
            }
        }
    }
}

// MARK: - Flow Layout

/// A layout that arranges views in a flowing manner.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, spacing: spacing, subviews: subviews)
        return CGSize(width: proposal.width ?? 0, height: result.height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, spacing: spacing, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            let point = result.positions[index]
            subview.place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var positions: [CGPoint] = []
        var height: CGFloat = 0
        
        init(in width: CGFloat, spacing: CGFloat, subviews: Subviews) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }
            
            height = y + lineHeight
        }
    }
}

// MARK: - Session Complete View

/// View shown when a study session is complete.
struct SessionCompleteView: View {
    
    let result: StudySessionResult?
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Celebration icon
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("Session Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let result = result {
                // Stats grid
                VStack(spacing: 16) {
                    HStack(spacing: 32) {
                        StatBadge(
                            value: "\(result.totalQuestions)",
                            label: "Reviewed",
                            color: .blue
                        )
                        
                        StatBadge(
                            value: "\(result.masteredCount)",
                            label: "Mastered",
                            color: .green
                        )
                    }
                    
                    HStack(spacing: 32) {
                        StatBadge(
                            value: result.formattedDuration,
                            label: "Time",
                            color: .purple
                        )
                        
                        StatBadge(
                            value: "\(result.scorePercentage)%",
                            label: "Score",
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            
            Button {
                onDismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Stat Badge

/// A badge displaying a statistic.
struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 100)
    }
}

// MARK: - Preview

#Preview {
    FlashcardSessionView(source: .allWords, learningOnly: false)
        .environmentObject(VocabViewModel())
}


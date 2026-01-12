//
//  StudyView.swift
//  BookVocab
//
//  Premium study hub with mode selection and progress tracking.
//  Beautiful cards and smooth animations.
//
//  Features:
//  - Source selection (book or all words)
//  - Progress visualization
//  - Study mode cards
//  - Quick action buttons
//

import SwiftUI
import os.log

private let logger = Logger(subsystem: "com.bookvocab.app", category: "StudyView")

struct StudyView: View {
    
    // MARK: - Environment
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @EnvironmentObject var booksViewModel: BooksViewModel
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // MARK: - State
    
    @State private var showingFlashcards: Bool = false
    @State private var showingMultipleChoice: Bool = false
    @State private var showingFillInBlank: Bool = false
    @State private var showingSourceSelection: Bool = false
    @State private var selectedSource: StudySource = .allWords
    @State private var learningOnly: Bool = true
    @State private var hasAppeared: Bool = false
    @State private var showUpgradeModal: Bool = false
    
    // MARK: - Computed Properties
    
    private var availableWords: [VocabWord] {
        switch selectedSource {
        case .allWords:
            return vocabViewModel.allWords
        case .book(let book):
            return vocabViewModel.fetchWords(forBook: book.id)
        }
    }
    
    private var studyableWords: [VocabWord] {
        learningOnly ? availableWords.filter { !$0.mastered } : availableWords
    }
    
    private var hasEnoughWords: Bool { studyableWords.count >= 1 }
    private var hasEnoughForQuiz: Bool { availableWords.count >= 4 }
    private var masteredCount: Int { availableWords.filter { $0.mastered }.count }
    private var learningCount: Int { availableWords.filter { !$0.mastered }.count }
    private var progress: Double {
        guard !availableWords.isEmpty else { return 0 }
        return Double(masteredCount) / Double(availableWords.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.lg) {
                    // Source selection
                    sourceCard
                        .padding(.horizontal, AppSpacing.horizontalPadding)
                        .padding(.top, AppSpacing.md)
                    
                    // Progress card
                    progressCard
                        .padding(.horizontal, AppSpacing.horizontalPadding)
                    
                    // Study modes
                    studyModesSection
                        .padding(.horizontal, AppSpacing.horizontalPadding)
                    
                    // Quick actions
                    if hasEnoughWords {
                        quickActionsSection
                            .padding(.horizontal, AppSpacing.horizontalPadding)
                    }
                }
                .padding(.bottom, AppSpacing.xxxl)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle("Study")
            .sheet(isPresented: $showingSourceSelection) {
                SourceSelectionView(
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
            // Upgrade modal for premium study modes
            .sheet(isPresented: $showUpgradeModal) {
                UpgradeView(reason: .studyModeRestricted)
            }
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Source Card
    
    private var sourceCard: some View {
        Button {
            showingSourceSelection = true
        } label: {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(AppColors.tanDark.opacity(0.5))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: selectedSource == .allWords ? "books.vertical.fill" : "book.fill")
                        .font(.title3)
                        .foregroundStyle(AppColors.primary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Studying")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(selectedSource.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Text("\(studyableWords.count) words available")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            }
            .padding(AppSpacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Progress Card
    
    private var progressCard: some View {
        VStack(spacing: AppSpacing.lg) {
            // Header with toggle
            HStack {
                Text("Your Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Learning only toggle
                HStack(spacing: AppSpacing.xs) {
                    Text("Learning only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Toggle("", isOn: $learningOnly)
                        .labelsHidden()
                        .scaleEffect(0.8)
                }
            }
            
            // Stats row
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text("\(availableWords.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("Total")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                
                VStack(spacing: 4) {
                    Text("\(masteredCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.success)
                    Text("Mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 1, height: 50)
                
                VStack(spacing: 4) {
                    Text("\(learningCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.warning)
                    Text("Learning")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Progress bar
            if !availableWords.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.15))
                            
                            Capsule()
                                .fill(AppColors.greenGradient)
                                .frame(width: geo.size.width * progress)
                                .animation(AppAnimation.smooth, value: progress)
                        }
                    }
                    .frame(height: 8)
                    
                    Text("\(Int(progress * 100))% mastered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .animation(AppAnimation.spring.delay(0.05), value: hasAppeared)
    }
    
    // MARK: - Study Modes Section
    
    private var studyModesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("Study Modes")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if !subscriptionManager.isPremium {
                    Text("Free: Flashcards only")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Flashcards (always available)
            StudyModeCardView(
                icon: "rectangle.on.rectangle.angled",
                title: "Flashcards",
                description: "Review words with flip cards",
                gradient: AppColors.blueGradient,
                wordCount: studyableWords.count,
                isDisabled: !hasEnoughWords,
                isPremiumLocked: false
            ) {
                logger.info("📚 Launching flashcards")
                showingFlashcards = true
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(AppAnimation.spring.delay(0.1), value: hasAppeared)
            
            // Multiple Choice (Premium only for free users)
            StudyModeCardView(
                icon: "list.bullet.circle.fill",
                title: "Multiple Choice",
                description: "Choose the correct definition",
                gradient: AppColors.purpleGradient,
                wordCount: availableWords.count,
                isDisabled: !hasEnoughForQuiz,
                isPremiumLocked: !subscriptionManager.isStudyModeAvailable(.multipleChoice)
            ) {
                if subscriptionManager.isStudyModeAvailable(.multipleChoice) {
                    logger.info("📚 Launching multiple choice")
                    showingMultipleChoice = true
                } else {
                    subscriptionManager.promptUpgrade(reason: .studyModeRestricted)
                    showUpgradeModal = true
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(AppAnimation.spring.delay(0.15), value: hasAppeared)
            
            // Fill in the Blank (Premium only for free users)
            StudyModeCardView(
                icon: "pencil.circle.fill",
                title: "Fill in the Blank",
                description: "Type the word from its definition",
                gradient: AppColors.orangeGradient,
                wordCount: availableWords.count,
                isDisabled: !hasEnoughForQuiz,
                isPremiumLocked: !subscriptionManager.isStudyModeAvailable(.fillInBlank)
            ) {
                if subscriptionManager.isStudyModeAvailable(.fillInBlank) {
                    logger.info("📚 Launching fill-in-blank")
                    showingFillInBlank = true
                } else {
                    subscriptionManager.promptUpgrade(reason: .studyModeRestricted)
                    showUpgradeModal = true
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(AppAnimation.spring.delay(0.2), value: hasAppeared)
        }
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Quick Start")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: AppSpacing.md) {
                QuickActionCardView(
                    icon: "arrow.clockwise",
                    title: "Review All",
                    subtitle: "\(availableWords.count) words",
                    color: .blue
                ) {
                    learningOnly = false
                    showingFlashcards = true
                }
                
                QuickActionCardView(
                    icon: "star.fill",
                    title: "Focus Mode",
                    subtitle: "\(learningCount) to learn",
                    color: AppColors.warning
                ) {
                    learningOnly = true
                    showingFlashcards = true
                }
            }
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
            .animation(AppAnimation.spring.delay(0.25), value: hasAppeared)
        }
    }
}

// MARK: - Source Selection View

struct SourceSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedSource: StudySource
    let vocabViewModel: VocabViewModel
    let booksViewModel: BooksViewModel
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    SourceRowView(
                        title: "All Words",
                        icon: "books.vertical.fill",
                        wordCount: vocabViewModel.totalWordCount,
                        masteredCount: vocabViewModel.masteredCount,
                        isSelected: selectedSource == .allWords
                    ) {
                        selectedSource = .allWords
                        dismiss()
                    }
                }
                
                Section("By Book") {
                    if booksViewModel.books.isEmpty {
                        Text("No books added yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(booksViewModel.books) { book in
                            let words = vocabViewModel.fetchWords(forBook: book.id)
                            let mastered = words.filter { $0.mastered }.count
                            
                            SourceRowView(
                                title: book.title,
                                icon: "book.fill",
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
            .navigationTitle("Select Words")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Source Row View

struct SourceRowView: View {
    let title: String
    let icon: String
    let wordCount: Int
    let masteredCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: AppSpacing.sm) {
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text("\(masteredCount) mastered")
                            .font(.caption)
                            .foregroundStyle(AppColors.success)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(AppColors.primary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(wordCount == 0)
        .opacity(wordCount == 0 ? 0.5 : 1)
    }
}

// MARK: - Study Mode Card View

struct StudyModeCardView: View {
    let icon: String
    let title: String
    let description: String
    let gradient: LinearGradient
    let wordCount: Int
    let isDisabled: Bool
    var isPremiumLocked: Bool = false
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    /// Effective disabled state (either not enough words OR premium locked)
    private var effectivelyDisabled: Bool {
        isDisabled && !isPremiumLocked
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.md) {
                // Icon
                ZStack {
                    if effectivelyDisabled {
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 52, height: 52)
                    } else if isPremiumLocked {
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .fill(gradient.opacity(0.1))
                            .frame(width: 52, height: 52)
                    } else {
                        RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous)
                            .fill(gradient.opacity(0.2))
                            .frame(width: 52, height: 52)
                    }
                    
                    Image(systemName: isPremiumLocked ? "lock.fill" : icon)
                        .font(.title2)
                        .foregroundStyle(effectivelyDisabled ? AnyShapeStyle(Color.gray) : (isPremiumLocked ? AnyShapeStyle(Color.orange) : AnyShapeStyle(gradient)))
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(effectivelyDisabled ? .secondary : .primary)
                        
                        if isPremiumLocked {
                            PremiumBadge(small: true)
                        } else if isDisabled && wordCount > 0 {
                            Text("(\(wordCount) words)")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    
                    Text(isPremiumLocked ? "Upgrade to Premium to unlock" : description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isPremiumLocked {
                    Image(systemName: "crown.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(AppSpacing.md)
            .cardStyle()
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                    .stroke(isPremiumLocked ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(effectivelyDisabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimation.quick, value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity) { } onPressingChanged: { pressing in
            isPressed = pressing
        }
    }
}

// MARK: - Quick Action Card View

struct QuickActionCardView: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(color)
                }
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(AppSpacing.md)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    StudyView()
        .environmentObject(VocabViewModel())
        .environmentObject(BooksViewModel())
}

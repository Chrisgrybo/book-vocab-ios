//
//  BookDetailView.swift
//  BookVocab
//
//  Premium book detail screen showing vocabulary words.
//  Beautiful hero header with book cover and progress stats.
//
//  Features:
//  - Large hero header with book cover
//  - Progress ring and stats
//  - Searchable word list
//  - Expandable word cards
//  - Smooth animations
//

import SwiftUI

struct BookDetailView: View {
    
    // MARK: - Properties
    
    let book: Book
    
    // MARK: - Environment
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    
    // MARK: - State
    
    @State private var showingAddVocab: Bool = false
    @State private var searchText: String = ""
    @State private var showMasteredOnly: Bool = false
    @State private var hasAppeared: Bool = false
    
    // MARK: - Computed Properties
    
    private var bookWords: [VocabWord] {
        vocabViewModel.fetchWords(forBook: book.id)
    }
    
    private var filteredWords: [VocabWord] {
        var words = bookWords
        
        if showMasteredOnly {
            words = words.filter { $0.mastered }
        }
        
        if !searchText.isEmpty {
            words = words.filter { word in
                word.word.localizedCaseInsensitiveContains(searchText) ||
                word.definition.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return words.sorted { $0.createdAt > $1.createdAt }
    }
    
    private var masteredCount: Int { bookWords.filter { $0.mastered }.count }
    private var learningCount: Int { bookWords.count - masteredCount }
    private var progress: Double {
        guard !bookWords.isEmpty else { return 0 }
        return Double(masteredCount) / Double(bookWords.count)
    }
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero header
                heroHeader
                
                // Stats cards
                statsSection
                    .padding(.top, -40)
                    .padding(.horizontal, AppSpacing.horizontalPadding)
                
                // Words section
                wordsSection
                    .padding(.top, AppSpacing.lg)
            }
        }
        .background(AppColors.groupedBackground)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search words...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addWordButton
            }
            
            ToolbarItem(placement: .secondaryAction) {
                filterMenu
            }
        }
        .sheet(isPresented: $showingAddVocab) {
            AddVocabView(bookId: book.id)
        }
        .onAppear {
            withAnimation(AppAnimation.spring.delay(0.1)) {
                hasAppeared = true
            }
        }
    }
    
    // MARK: - Hero Header
    
    private var heroHeader: some View {
        ZStack(alignment: .bottom) {
            // Background
            LinearGradient(
                colors: [
                    AppColors.tanDark,
                    AppColors.groupedBackground
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 280)
            
            // Content
            VStack(spacing: AppSpacing.md) {
                // Book cover
                bookCoverView
                    .frame(width: 120, height: 170)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Book info
                VStack(spacing: AppSpacing.xxs) {
                    Text(book.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(book.author)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Added \(book.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.bottom, 60)
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 20)
        }
    }
    
    private var bookCoverView: some View {
        Group {
            if let coverUrl = book.coverImageUrl, !coverUrl.isEmpty, let url = URL(string: coverUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        coverPlaceholder
                    case .empty:
                        coverPlaceholder
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    @unknown default:
                        coverPlaceholder
                    }
                }
            } else {
                coverPlaceholder
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.medium, style: .continuous))
    }
    
    private var coverPlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppColors.tanDark, AppColors.tan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: "book.closed.fill")
                .font(.largeTitle)
                .foregroundStyle(AppColors.primary.opacity(0.5))
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        HStack(spacing: AppSpacing.md) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppColors.greenGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(AppAnimation.smooth, value: progress)
                
                VStack(spacing: 0) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("done")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 70, height: 70)
            
            // Stats
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                StatRow(icon: "textformat.abc", value: "\(bookWords.count)", label: "words", color: .blue)
                StatRow(icon: "checkmark.circle.fill", value: "\(masteredCount)", label: "mastered", color: AppColors.success)
                StatRow(icon: "book.fill", value: "\(learningCount)", label: "learning", color: AppColors.warning)
            }
            
            Spacer()
        }
        .padding(AppSpacing.md)
        .cardStyle()
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
    }
    
    // MARK: - Words Section
    
    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            // Header
            HStack {
                Text("Vocabulary")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(filteredWords.count) words")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, AppSpacing.horizontalPadding)
            
            // Filter pills
            if !bookWords.isEmpty {
                filterPills
                    .padding(.horizontal, AppSpacing.horizontalPadding)
            }
            
            // Words list
            if filteredWords.isEmpty {
                emptyWordsState
                    .padding(.top, AppSpacing.xl)
            } else {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(Array(filteredWords.enumerated()), id: \.element.id) { index, word in
                        WordCardView(word: word)
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 20)
                            .animation(
                                AppAnimation.spring.delay(Double(index) * 0.03),
                                value: hasAppeared
                            )
                    }
                }
                .padding(.horizontal, AppSpacing.horizontalPadding)
            }
        }
        .padding(.bottom, AppSpacing.xxxl)
    }
    
    private var filterPills: some View {
        HStack(spacing: AppSpacing.xs) {
            FilterChip(
                title: "All",
                isSelected: !showMasteredOnly,
                count: bookWords.count
            ) {
                withAnimation(AppAnimation.spring) {
                    showMasteredOnly = false
                }
            }
            
            FilterChip(
                title: "Mastered",
                isSelected: showMasteredOnly,
                count: masteredCount
            ) {
                withAnimation(AppAnimation.spring) {
                    showMasteredOnly = true
                }
            }
            
            Spacer()
        }
    }
    
    private var emptyWordsState: some View {
        VStack(spacing: AppSpacing.lg) {
            Image(systemName: "text.book.closed")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
            
            VStack(spacing: AppSpacing.xs) {
                Text("No Words Yet")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Start adding vocabulary words\nfrom this book.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddVocab = true
            } label: {
                Label("Add First Word", systemImage: "plus")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, AppSpacing.xxxl)
        }
        .padding(AppSpacing.xl)
    }
    
    // MARK: - Toolbar Items
    
    private var addWordButton: some View {
        Button {
            showingAddVocab = true
        } label: {
            Image(systemName: "plus")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(AppColors.primary)
                .clipShape(Circle())
        }
    }
    
    private var filterMenu: some View {
        Menu {
            Toggle("Show Mastered Only", isOn: $showMasteredOnly)
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
}

// MARK: - Stat Row

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xxs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.3) : Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.xs)
            .background {
                if isSelected {
                    AppColors.primary
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Word Card View

struct WordCardView: View {
    let word: VocabWord
    
    @EnvironmentObject var vocabViewModel: VocabViewModel
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row (always visible)
            HStack(alignment: .top, spacing: AppSpacing.md) {
                // Word info
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    HStack {
                        Text(word.word)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if word.mastered {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundStyle(AppColors.success)
                        }
                    }
                    
                    Text(word.definition)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                // Mastered toggle
                Button {
                    Task {
                        await vocabViewModel.toggleMastered(word)
                    }
                } label: {
                    Image(systemName: word.mastered ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(word.mastered ? AppColors.success : Color.gray.opacity(0.3))
                }
                .buttonStyle(.plain)
            }
            
            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Divider()
                        .padding(.vertical, AppSpacing.sm)
                    
                    if !word.exampleSentence.isEmpty {
                        DetailSection(
                            title: "Example",
                            icon: "text.quote",
                            content: "\"\(word.exampleSentence)\""
                        )
                    }
                    
                    if !word.synonyms.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Synonyms", systemImage: "equal.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            FlexibleView(data: word.synonyms, spacing: 6, alignment: .leading) { synonym in
                                Text(synonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    if !word.antonyms.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Label("Antonyms", systemImage: "arrow.left.arrow.right.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            FlexibleView(data: word.antonyms, spacing: 6, alignment: .leading) { antonym in
                                Text(antonym)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundStyle(.orange)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            
            // Expand indicator
            HStack {
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .padding(.top, AppSpacing.xs)
        }
        .padding(AppSpacing.md)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AppAnimation.spring) {
                isExpanded.toggle()
            }
        }
    }
}

// MARK: - Detail Section

struct DetailSection: View {
    let title: String
    let icon: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(content)
                .font(.subheadline)
                .italic()
                .foregroundStyle(.primary.opacity(0.8))
        }
    }
}

// MARK: - Flexible View (for wrapping pills)

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var availableWidth: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: Alignment(horizontal: alignment, vertical: .center)) {
            Color.clear
                .frame(height: 1)
                .readSize { size in
                    availableWidth = size.width
                }
            
            _FlexibleView(
                availableWidth: availableWidth,
                data: data,
                spacing: spacing,
                alignment: alignment,
                content: content
            )
        }
    }
}

struct _FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let availableWidth: CGFloat
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content
    
    @State private var elementsSize: [Data.Element: CGSize] = [:]
    
    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(computeRows(), id: \.self) { rowElements in
                HStack(spacing: spacing) {
                    ForEach(rowElements, id: \.self) { element in
                        content(element)
                            .fixedSize()
                            .readSize { size in
                                elementsSize[element] = size
                            }
                    }
                }
            }
        }
    }
    
    func computeRows() -> [[Data.Element]] {
        var rows: [[Data.Element]] = [[]]
        var currentRow = 0
        var remainingWidth = availableWidth
        
        for element in data {
            let elementSize = elementsSize[element, default: CGSize(width: availableWidth, height: 1)]
            
            if remainingWidth - (elementSize.width + spacing) >= 0 {
                rows[currentRow].append(element)
            } else {
                currentRow += 1
                rows.append([element])
                remainingWidth = availableWidth
            }
            
            remainingWidth -= elementSize.width + spacing
        }
        
        return rows
    }
}

extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometryProxy in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geometryProxy.size)
            }
        )
        .onPreferenceChange(SizePreferenceKey.self, perform: onChange)
    }
}

private struct SizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {}
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BookDetailView(book: Book.sample)
            .environmentObject(VocabViewModel())
    }
}

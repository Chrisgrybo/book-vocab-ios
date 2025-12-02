# Book Vocab - iOS App

A SwiftUI iOS application for tracking vocabulary words from books you read.

## Overview

Book Vocab helps users build their vocabulary by collecting and organizing words from their reading. Users can add books to their collection, save vocabulary words with definitions, synonyms, antonyms, and example sentences, then study them through flashcards and quizzes.

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## Architecture

This app follows the **MVVM (Model-View-ViewModel)** architecture pattern:

```
BookVocab/
├── BookVocabApp.swift           # App entry point
├── Config/                       # Configuration (credentials)
│   ├── Secrets.swift            # ⚠️ Gitignored - your credentials
│   └── Secrets.example.swift    # Template for Secrets.swift
├── Models/                       # Data models
│   ├── Book.swift               # Book model
│   ├── VocabWord.swift          # Vocabulary word model
│   └── User.swift               # User model
├── ViewModels/                   # View models (business logic)
│   ├── UserSessionViewModel.swift # Authentication & session
│   ├── BooksViewModel.swift     # Book management
│   ├── VocabViewModel.swift     # Vocabulary management
│   └── StudyViewModel.swift     # Study session logic
├── Views/                        # SwiftUI views
│   ├── MainTabView.swift        # Main tab navigation
│   ├── Auth/
│   │   └── LoginView.swift      # Login/Signup screen
│   ├── Home/
│   │   ├── HomeView.swift       # Book list with covers & stats
│   │   ├── AddBookView.swift    # Add book with cover search
│   │   └── BookDetailView.swift # Book details & vocab
│   ├── Vocab/
│   │   ├── AddVocabView.swift   # Add word with dictionary lookup
│   │   └── AllVocabView.swift   # All words list
│   └── Study/
│       └── StudyView.swift      # Study section (placeholder)
└── Services/                     # Backend services
    ├── SupabaseService.swift    # Supabase auth & database
    ├── DictionaryService.swift  # Free Dictionary API
    └── BookSearchService.swift  # Google Books API
```

## Features

### ✅ Implemented

- [x] User authentication flow (Login/Signup with email/password)
- [x] Supabase authentication integration
- [x] Supabase database operations (books, vocab words)
- [x] Secure configuration system (`Secrets.swift` gitignored)
- [x] Book collection management with cover images
- [x] **Google Books API integration** - Auto-fetch book covers
- [x] **Free Dictionary API integration** - Auto-fetch definitions, synonyms, antonyms, examples
- [x] Vocabulary word tracking with:
  - Definitions
  - Synonyms & Antonyms
  - Example sentences
  - Mastery tracking
- [x] Enhanced HomeView with:
  - Book covers (thumbnails)
  - Word count per book
  - Vocabulary progress stats
  - Search/filter books
- [x] Global vocabulary list with filtering & sorting
- [x] Study section placeholder (flashcards & quizzes)
- [x] Tab-based navigation

### 🚧 TODO (Not Yet Implemented)

- [ ] Flashcard study mode
- [ ] Quiz study mode
- [ ] Offline caching
- [ ] Push notifications for study reminders
- [ ] Sign in with Apple (removed, can re-add)

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd book-vocab-ios
   ```

2. **Open in Xcode**
   ```bash
   open BookVocab.xcodeproj
   ```

3. **Build and Run**
   - Select a simulator or device (iOS 17.0+)
   - Press `Cmd + R` to build and run

## Configuration

### Supabase Setup

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Copy `BookVocab/Config/Secrets.example.swift` to `BookVocab/Config/Secrets.swift`
3. Update with your credentials:
   ```swift
   enum Secrets {
       static let supabaseUrl = "https://your-project.supabase.co"
       static let supabaseKey = "your-anon-key"
   }
   ```

> ⚠️ **Important:** `Secrets.swift` is gitignored and should never be committed. Each developer must create their own copy.

### Database Schema (Supabase)

```sql
-- Books table
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  cover_image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vocabulary words table
CREATE TABLE vocab_words (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  definition TEXT NOT NULL,
  synonyms TEXT[] DEFAULT '{}',
  antonyms TEXT[] DEFAULT '{}',
  example_sentence TEXT,
  mastered BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocab_words ENABLE ROW LEVEL SECURITY;
```

## Dependencies

- **[Supabase Swift SDK](https://github.com/supabase/supabase-swift)** - Authentication & database

### External APIs (No SDK Required)

- **[Free Dictionary API](https://dictionaryapi.dev/)** - Word definitions, synonyms, antonyms
- **[Google Books API](https://developers.google.com/books)** - Book search & cover images

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Acknowledgments

- Built with SwiftUI and modern iOS development practices
- Designed for iOS 17+ with latest SwiftUI features


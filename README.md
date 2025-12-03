# Book Vocab - iOS App

A SwiftUI iOS application for tracking vocabulary words from books you read. **Now with full offline support!**

## Overview

Book Vocab helps users build their vocabulary by collecting and organizing words from their reading. Users can add books to their collection, save vocabulary words with definitions, synonyms, antonyms, and example sentences, then study them through flashcards and quizzes — all with full offline support.

## 🚀 Quick Start Guide

### 1. Create an Account
- Launch the app
- Enter your email and password
- Tap "Sign Up" to create a new account (or "Sign In" if you have one)

### 2. Add Your First Book
- Tap the **+** button on the Home screen
- Search for a book by title (covers are auto-fetched from Google Books)
- Select a result or enter details manually
- Tap "Add" to save

### 3. Add Vocabulary Words

**From a Book:**
- Tap on a book to view its details
- Tap **+** in the toolbar
- Enter a word and tap 🔍 to look it up
- Definition, synonyms, antonyms, and examples are auto-filled
- Edit if needed, then tap "Save"

**From the Words Tab (New!):**
- Go to the **Words** tab
- Tap **+** in the toolbar
- Choose a book from the picker, or leave as "None (All Words)" for a global word
- Look up the word and save

> 💡 **Tip**: Global words (not assigned to any book) appear only in the Words tab and can be studied in "All Words" mode.

### 4. Study Your Words
- Go to the **Study** tab
- Choose a study source (All Words or a specific book)
- Select a mode:
  - **Flashcards**: Tap to flip, swipe right if you know it, swipe left to skip
  - **Multiple Choice**: Pick the correct definition
  - **Fill in the Blank**: Type the word from its definition

**After completing a session:**
- Review all words you studied on the **Summary Screen**
- **Select which words to mark as mastered** using checkboxes
- Tap **"Save"** to persist your selections
- Words you didn't select remain in "learning" mode

> 💡 **New!** Words are no longer auto-marked as mastered. You have full control over which words you've truly learned.

### 5. Track Your Progress
- View stats on the Home and Study screens
- Words marked as "mastered" are tracked
- Filter to study only words you're still learning

## 📴 Offline Functionality

**Book Vocab works fully offline!**

- **Books & Vocab**: All added books and vocabulary words are cached locally using Core Data
- **Study Sessions**: Flashcards and quizzes work without an internet connection
- **Auto-Sync**: Changes made offline are automatically synced to Supabase when you're back online
- **Offline Indicator**: A banner appears when you're offline

> 💡 **Tip**: Add books and look up words while online, then study anywhere — even without Wi-Fi!

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
│   ├── VocabWord.swift          # Vocabulary word model (optional bookId)
│   └── User.swift               # User model
├── ViewModels/                   # View models (business logic)
│   ├── UserSessionViewModel.swift # Authentication & session
│   ├── BooksViewModel.swift     # Book management + caching
│   ├── VocabViewModel.swift     # Vocabulary management + caching
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
│   │   ├── AddVocabView.swift   # Add word with dictionary lookup & book picker
│   │   └── AllVocabView.swift   # All words list with add button
│   ├── Study/
│   │   ├── StudyView.swift      # Study hub with mode selection
│   │   ├── FlashcardView.swift  # Flashcard study mode
│   │   └── QuizView.swift       # Quiz modes (MC & fill-in)
│   └── Components/
│       ├── Theme.swift          # Design system (colors, spacing, styles)
│       └── AdMRECView.swift     # MREC banner ad component
└── Services/                     # Backend & offline services
    ├── SupabaseService.swift    # Supabase auth & database
    ├── DictionaryService.swift  # Free Dictionary API
    ├── BookSearchService.swift  # Google Books API
    ├── PersistenceController.swift # Core Data stack
    ├── CacheService.swift       # Local caching operations
    ├── NetworkMonitor.swift     # Connectivity detection
    ├── SyncService.swift        # Offline sync management
    └── AdManager.swift          # AdMob ad management singleton
```

## Features

### ✅ Fully Implemented

- [x] **Supabase Authentication** (email/password login & signup)
- [x] **Secure Configuration** (`Secrets.swift` gitignored)
- [x] **Google Books API** - Auto-fetch book covers by title
- [x] **Free Dictionary API** - Auto-fetch definitions, synonyms, antonyms, examples
- [x] **Book Collection Management**
  - Add/delete books
  - Book covers displayed as thumbnails
  - Word count per book
- [x] **Vocabulary Tracking**
  - Definitions, synonyms, antonyms, example sentences
  - Mastery status toggle
  - Global vocabulary list with search & filters
  - **Add words from Words tab** with book picker
  - **Global words** (unassigned) supported
- [x] **Dictionary Autofill**
  - Automatically fills definition, synonyms, antonyms, example
  - **Fixed**: Fields now reset correctly when looking up a new word
- [x] **Study Section**
  - 📇 Flashcards with 3D flip animation & swipe gestures
  - 📝 Multiple choice quiz
  - ✏️ Fill-in-the-blank quiz
  - 📊 Progress tracking & session summaries
  - 🎯 Study by book or all words
  - 🔄 "Learning only" filter
  - ✅ **Manual mastery selection** — choose which words to mark as mastered after each session
- [x] **Offline Caching**
  - Core Data local storage
  - Network connectivity monitoring
  - Auto-sync when back online
  - Offline indicator banner
- [x] **Modern UI**
  - Warm tan & cream color palette with black accents
  - Consistent card styling and spacing
  - Smooth animations throughout
  - Polished login/signup screen matching app theme
- [x] **Tab-based Navigation** (Books, Words, Study)

- [x] **AdMob Integration**
  - MREC (300x250) banner ads in lists
  - Interstitial ads after study sessions
  - Premium ad-removal option (`isPremium` flag)

### 🚧 TODO (Future Enhancements)

- [ ] Push notifications for study reminders
- [ ] Sign in with Apple
- [ ] In-app purchases for premium upgrade
- [ ] Spaced repetition algorithm
- [ ] Export/import vocabulary lists

## 📺 AdMob Integration

Book Vocab uses Google AdMob for monetization with a premium ad-removal option.

### Ad Placements

#### MREC Banner Ads (300x250)
- **Home View (Books)**: Inserted after every 5 books
- **All Words View**: Inserted after every 5 vocabulary words
- **Book Detail View**: One at the top of the word list, then every 5 words

#### Interstitial Ads
- **After Study Sessions**: Shown after user taps "Save" on the session summary screen
- 1.5 second delay to let user see the "saved" confirmation
- Only displayed after save action, never during active study
- App returns to study tab after ad is dismissed

### Premium Ad Removal

Users can remove all ads by setting `isPremium = true` (stored in `@AppStorage`):

```swift
// Check premium status anywhere in the app
@AppStorage("isPremium") var isPremium: Bool = false

// All ads are wrapped with:
if !isPremium { AdMRECView() }
```

### Ad Unit IDs

The app uses **test ad unit IDs** by default. To switch to production:

1. Open `BookVocab/Services/AdManager.swift`
2. Replace the test IDs with your production IDs:

```swift
// Current (Test IDs - for development only)
static let mrecAdUnitID = "ca-app-pub-3940256099942544/6300978111"
static let interstitialAdUnitID = "ca-app-pub-3940256099942544/1033173712"

// Replace with your production IDs:
static let mrecAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY"
static let interstitialAdUnitID = "ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ"
```

### Required Setup

1. **Add Google Mobile Ads SDK** via Swift Package Manager:
   - In Xcode: File → Add Package Dependencies
   - URL: `https://github.com/googleads/swift-package-manager-google-mobile-ads`
   - Add `GoogleMobileAds` product to your target

2. **Configure Info.plist** (required for AdMob):
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY</string>
   <key>SKAdNetworkItems</key>
   <array>
       <!-- Add SKAdNetwork IDs from Google's documentation -->
   </array>
   ```

3. **App Transport Security** (if needed):
   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSAllowsArbitraryLoads</key>
       <true/>
   </dict>
   ```

### Safety Rules

- Ads only show if user has 5+ items (books or words)
- No multiple ads in a row
- Interstitials never interrupt active study
- All ads respect premium status

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Chrisgrybo/book-vocab-ios.git
   cd book-vocab-ios
   ```

2. **Configure Supabase credentials**
   ```bash
   cp BookVocab/Config/Secrets.example.swift BookVocab/Config/Secrets.swift
   ```
   Then edit `Secrets.swift` with your Supabase URL and anon key.

3. **Open in Xcode**
   ```bash
   open BookVocab.xcodeproj
   ```

4. **Build and Run**
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
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,  -- NULL for global words
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
- **[Google Mobile Ads SDK](https://github.com/googleads/swift-package-manager-google-mobile-ads)** - AdMob monetization
- **Core Data** - Local offline caching (built into iOS)

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
- Offline-first architecture for reliable user experience
- Warm, book-inspired aesthetic with tan backgrounds and black accents

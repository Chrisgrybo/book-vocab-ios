# Read & Recall - iOS App

A SwiftUI iOS application for tracking vocabulary words from books you read. **Now with full offline support!**

## Overview

Read & Recall helps users build their vocabulary by collecting and organizing words from their reading. Users can add books to their collection, save vocabulary words with definitions, synonyms, antonyms, and example sentences, then study them through flashcards and quizzes — all with full offline support.

## 🚀 Quick Start Guide

### 1. Complete Onboarding (New Users)
New users will see an **onboarding flow** when first launching the app:

1. **Welcome Screen** — Learn about the app's value proposition
2. **Profile Setup** — Enter your display name (optional)
3. **Study Preferences** — Choose your preferred study mode and notification settings
4. **Subscription Paywall** — Start a **1-month free trial** or continue with the free tier
5. **Completion** — You're all set! Start reading and building vocabulary

> 💡 **Free Trial**: Premium includes unlimited books, unlimited words, all study modes, and no ads. The trial lasts 1 month and can be cancelled anytime.

### 2. Sign In (Returning Users)
- Launch the app
- Enter your email and password
- Tap "Sign In" to access your account

### 3. Add Your First Book
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
1. View the **Summary Screen** with all words you studied
2. See which words you got right ✅ and which you missed ❌
3. **Select which words to mark as mastered** using checkboxes
4. Tap **"Save"** to persist your selections
5. An interstitial ad may appear (after a brief delay)
6. Return to the Study tab

> 💡 **Manual Mastery Control** — Words are never auto-marked as mastered. You decide which words you've truly learned after each session.

> 📺 **Ad Timing** — Interstitial ads only appear *after* you save your progress, never during active study or before your data is saved.

### 5. Track Your Progress
- View stats on the Home and Study screens
- Words marked as "mastered" are tracked
- Filter to study only words you're still learning

## 📴 Offline Functionality

**Read & Recall works fully offline!**

- **Books & Vocab**: All added books and vocabulary words are cached locally using Core Data
- **Study Sessions**: Flashcards and quizzes work without an internet connection
- **Auto-Sync**: Changes made offline are automatically synced to Supabase when you're back online
- **Offline Indicator**: A banner appears when you're offline

> 💡 **Tip**: Add books and look up words while online, then study anywhere — even without Wi-Fi!

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## 🔐 Required Environment Secrets

The app requires several API keys to be configured in `BookVocab/Config/Secrets.swift`. Copy the example file and fill in your credentials:

```bash
cp BookVocab/Config/Secrets.example.swift BookVocab/Config/Secrets.swift
```

| Secret | Required | Source | Description |
|--------|----------|--------|-------------|
| `supabaseUrl` | ✅ Yes | [supabase.com](https://supabase.com) | Your Supabase project URL |
| `supabaseKey` | ✅ Yes | Supabase Dashboard | Your Supabase anon/public key |
| `mixpanelToken` | ⚠️ Recommended | [mixpanel.com](https://mixpanel.com) | Analytics token (app works without it) |

**AdMob Configuration** (in `Info.plist`):

| Key | Required | Description |
|-----|----------|-------------|
| `GADApplicationIdentifier` | ✅ For ads | Your AdMob App ID |

> ⚠️ **Important:** `Secrets.swift` is gitignored and must never be committed. Test ad unit IDs are used by default in `AdManager.swift`.

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
│   ├── Onboarding/
│   │   ├── OnboardingView.swift      # Onboarding coordinator
│   │   ├── WelcomeView.swift         # Welcome screen
│   │   ├── ProfileSetupView.swift    # Name/avatar setup
│   │   ├── PreferencesView.swift     # Study preferences
│   │   ├── PaywallView.swift         # Subscription offer
│   │   └── OnboardingCompletionView.swift # Success screen
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
│   ├── Premium/
│   │   └── UpgradeView.swift    # Premium upgrade modal
│   ├── Settings/
│   │   └── SettingsView.swift   # Profile & subscription management
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
    ├── AdManager.swift          # AdMob ad management singleton
    ├── AnalyticsService.swift   # Mixpanel analytics wrapper
    └── SubscriptionManager.swift # StoreKit 2 subscription handling
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
  - 🔒 **Fixed flashcard flow** — ads only show after saving, data is never lost
- [x] **Offline Caching**
  - Core Data local storage
  - Network connectivity monitoring
  - Auto-sync when back online
  - Offline indicator banner
- [x] **Modern UI**
  - Warm tan & cream color palette with black accents
  - Consistent card styling and spacing (22–28pt corner radius)
  - Smooth animations throughout (spring & easeInOut)
  - Redesigned login/signup screen with card-based layout
  - Gradient headers and unified design system (`Theme.swift`)
- [x] **Tab-based Navigation** (Books, Words, Study)

- [x] **AdMob Integration**
  - MREC (300x250) banner ads in lists
  - Interstitial ads after study sessions
  - Premium ad-removal option

- [x] **Freemium Model**
  - Free tier: 3 books, 16 words/book, flashcards only
  - Premium tier: Unlimited books/words, all study modes, no ads
  - Monthly subscription ($2.99) via StoreKit 2
  - Restore purchases functionality
  - Limit enforcement with upgrade prompts

- [x] **Mixpanel Analytics**
  - User authentication tracking (signup, login, logout)
  - Book & word management events
  - Study session analytics (mode, duration, accuracy)
  - Revenue & freemium event tracking (ready for IAP)
  - Offline event queueing
  - User profile management

- [x] **User Profile & Settings**
  - Editable display name
  - Progress stats (books, words, mastered, sessions)
  - Notification preferences
  - Daily reminder time picker
  - Preferred study mode setting
  - Offline caching of profile/settings

### 🚧 TODO (Future Enhancements)

- [ ] Push notifications for study reminders
- [ ] Sign in with Apple
- [ ] Spaced repetition algorithm
- [ ] Export/import vocabulary lists
- [ ] Avatar upload

## 👑 Freemium Model & Subscription

Read & Recall uses a freemium business model with a **1-month free trial** and monthly subscription.

### Free Trial (New Users)

New users can start a **1-month free trial** during onboarding:
- Full premium access for 30 days
- Automatically converts to paid unless cancelled
- One trial per Apple ID
- Cancel anytime in App Store settings

### Free Tier

| Feature | Limit |
|---------|-------|
| Books | Up to 3 |
| Words per book | Up to 16 |
| Study Modes | Flashcards only |
| Ads | Enabled (MREC + Interstitial) |

### Premium Tier ($2.99/month)

| Feature | Access |
|---------|--------|
| Books | Unlimited |
| Words per book | Unlimited |
| Study Modes | All (Flashcards, Multiple Choice, Fill-in-the-Blank) |
| Ads | Completely removed |

### Onboarding Flow

New users complete a 5-step onboarding:

1. **Welcome** — App introduction and value proposition
2. **Profile Setup** — Display name (optional)
3. **Preferences** — Preferred study mode, notification settings
4. **Paywall** — Free trial offer with clear App Store terms
5. **Completion** — Success message and next steps

The onboarding only shows once. Returning users skip directly to the main app.

### Limit Enforcement

When a user reaches a free tier limit:
1. A modal appears explaining the limit
2. Premium benefits are highlighted
3. User can upgrade or dismiss

```swift
// Check limits in your code
if subscriptionManager.canAddBook(currentCount: bookCount) {
    // Proceed with adding book
} else {
    subscriptionManager.promptUpgrade(reason: .bookLimit)
}
```

### Subscription Management

The `SubscriptionManager` singleton handles:
- StoreKit 2 product loading
- Purchase processing (with free trial support)
- Restore purchases
- Subscription status tracking
- Premium status persistence to Supabase

```swift
// Access subscription status
@StateObject var subscriptionManager = SubscriptionManager.shared

// Check premium status
if subscriptionManager.isPremium {
    // Premium features available
}

// Start free trial / purchase
await subscriptionManager.purchaseMonthlyPremium()

// Restore purchases
await subscriptionManager.restorePurchases()
```

### Analytics Events

Freemium events tracked via Mixpanel:
- `Limit Reached` - When user hits a free tier limit
- `Upgrade Modal Shown` - When upgrade prompt appears
- `Premium Purchased` - Successful subscription
- `Purchase Failed` - Failed purchase attempt
- `Purchase Restored` - Successful restore

### In-App Purchase Product ID

| Product | ID | Price |
|---------|-----|-------|
| Monthly Premium | `com.bookvocab.premium.monthly` | $2.99 |

> ⚠️ **Testing**: Use sandbox testers in App Store Connect for testing purchases during development.

## 📺 AdMob Integration

Read & Recall uses Google AdMob for monetization with a premium ad-removal option.

### Ad Placements

#### MREC Banner Ads (300x250)
- **Home View (Books)**: Inserted after every 5 books
- **All Words View**: Inserted after every 5 vocabulary words
- **Book Detail View**: One at the top of the word list, then every 5 words

#### Interstitial Ads
- **After Study Sessions**: Shown after user taps "Save" on the session summary screen
- **Timing flow**:
  1. User completes flashcards or quiz → Summary screen appears
  2. User reviews results and selects words to mark as mastered
  3. User taps "Save" → Progress is persisted to database
  4. Brief delay (1.5s) → Interstitial ad appears
  5. User dismisses ad → Returns to Study tab
- **Key guarantee**: Progress is always saved *before* the ad appears
- Never interrupts active study or blocks data saving

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

## 📊 Mixpanel Analytics Integration

Read & Recall uses Mixpanel for comprehensive analytics tracking with offline support.

### Setup

1. Create a Mixpanel account at [mixpanel.com](https://mixpanel.com) (free tier available)
2. Create a new project for Read & Recall
3. Copy your Project Token from Settings > Project Settings
4. Add to your `Secrets.swift`:

```swift
static let mixpanelToken = "your-mixpanel-token"
```

### Tracked Events

#### Authentication Events
| Event | Properties | When Triggered |
|-------|------------|----------------|
| `Sign Up` | `user_id` | User creates account |
| `Login` | `user_id` | User logs in |
| `Logout` | - | User logs out |
| `Login Failed` | `error` | Login attempt fails |
| `Sign Up Failed` | `error` | Signup attempt fails |

#### Book Management Events
| Event | Properties | When Triggered |
|-------|------------|----------------|
| `Book Added` | `book_title`, `book_author`, `has_cover` | User adds a book |
| `Book Deleted` | `book_title` | User deletes a book |
| `Book Viewed` | `book_title`, `word_count` | User opens book detail |

#### Word Management Events
| Event | Properties | When Triggered |
|-------|------------|----------------|
| `Word Added` | `word`, `book_title`, `is_global_word` | User adds a word |
| `Word Deleted` | `word` | User deletes a word |
| `Word Looked Up` | `word`, `success` | Dictionary lookup |
| `Word Mastery Toggled` | `word`, `mastered` | Mastery status changed |
| `Words Mastered From Session` | `mastered_count`, `study_mode` | User saves mastery from summary |

#### Study Session Events
| Event | Properties | When Triggered |
|-------|------------|----------------|
| `Study Session Started` | `study_mode`, `study_source`, `word_count` | Session begins |
| `Study Session Completed` | `study_mode`, `study_source`, `word_count`, `correct_count`, `mastered_count`, `duration_seconds`, `score_percentage` | Session ends |
| `Flashcard Swiped` | `swipe_direction`, `card_index`, `total_cards` | User swipes flashcard |
| `Quiz Answer Submitted` | `is_correct`, `question_index`, `total_questions`, `question_type` | User answers quiz |

#### Revenue & Freemium Events (Ready for IAP)
| Event | Properties | When Triggered |
|-------|------------|----------------|
| `Premium Purchased` | `plan_type`, `price`, `currency`, `transaction_id` | User purchases premium |
| `Trial Started` | `plan_type`, `duration_days` | User starts trial |
| `Subscription Renewed` | `plan_type`, `price`, `currency` | Subscription renews |
| `Subscription Cancelled` | `plan_type` | User cancels |
| `Ads Removed` | `method`, `plan_type` | Ads disabled |
| `Purchase Failed` | `error_message` | Purchase attempt fails |

### User Profile Properties

The following properties are set on user profiles:

| Property | Type | Description |
|----------|------|-------------|
| `is_premium` | Boolean | Whether user has premium |
| `premium_plan_type` | String | monthly/annual |
| `ad_free` | Boolean | Whether ads are disabled |
| `total_spent` | Number | Cumulative revenue |

### Debug Logging

In debug builds, all analytics events are logged to the console with the `📊` prefix:

```
📊 Tracked: Study Session Started
📊 Properties: ["study_mode": "Flashcards", "word_count": 10]
```

Production builds have logging disabled.

### Adding New Events

To add a new event:

1. Add the event to `AnalyticsEvent` enum in `AnalyticsService.swift`
2. Add any new properties to `AnalyticsProperty` enum
3. (Optional) Create a convenience method for complex events
4. Call `AnalyticsService.shared.track(.yourEvent, properties: [...])`

Example:
```swift
// In AnalyticsService.swift
enum AnalyticsEvent: String {
    case newFeatureUsed = "New Feature Used"
}

// In your view/viewmodel
AnalyticsService.shared.track(.newFeatureUsed, properties: [
    "feature_name": "gamification",
    "level": 5
])
```

## 👤 User Profile & Settings

Read & Recall uses `user_profiles` and `user_settings` tables to store user data that persists across devices.

### User Profile (`user_profiles`)

Stores display information and aggregated stats:

| Field | Type | Description |
|-------|------|-------------|
| `display_name` | TEXT | User's chosen display name |
| `avatar_url` | TEXT | URL to profile picture (future) |
| `total_books` | INTEGER | Total books in collection |
| `total_words` | INTEGER | Total vocabulary words |
| `mastered_words` | INTEGER | Words marked as mastered |
| `total_study_sessions` | INTEGER | Completed study sessions |

Stats are automatically updated when:
- A book is added/deleted
- A word is added/deleted
- A word's mastery status changes
- A study session is completed

### User Settings (`user_settings`)

Stores preferences and subscription status:

| Field | Type | Description |
|-------|------|-------------|
| `is_premium` | BOOLEAN | Premium subscription active |
| `subscription_product_id` | TEXT | Active product ID |
| `subscription_expires_at` | TIMESTAMP | Expiration date |
| `notifications_enabled` | BOOLEAN | Daily reminders on/off |
| `daily_reminder_time` | TIME | When to send reminder |
| `preferred_study_mode` | TEXT | Default study mode |
| `feature_flags` | JSONB | A/B testing flags |

### Offline Support

Both profile and settings are cached locally for offline use:

```swift
// Cached in @AppStorage
@AppStorage("cachedIsPremium") var cachedIsPremium: Bool
@AppStorage("cachedDisplayName") var cachedDisplayName: String
// ... etc.
```

Changes sync to Supabase when online.

### Accessing Profile/Settings

In views, access via `UserSessionViewModel`:

```swift
@EnvironmentObject var session: UserSessionViewModel

// Get display name
Text(session.displayName)

// Check premium status
if session.isPremium {
    // Premium features
}

// Get profile stats
Text("\\(session.userProfile?.totalBooks ?? 0) books")

// Update settings
try await session.updateNotificationSettings(enabled: true, reminderTime: "09:00")
```

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
       // Supabase
       static let supabaseUrl = "https://your-project.supabase.co"
       static let supabaseKey = "your-anon-key"
       
       // Mixpanel (get from mixpanel.com > Settings > Project Settings)
       static let mixpanelToken = "your-mixpanel-token"
   }
   ```

> ⚠️ **Important:** `Secrets.swift` is gitignored and should never be committed. Each developer must create their own copy.

### Database Schema (Supabase)

The complete database schema is available in the `supabase/migrations/` folder:
- `001_initial_schema.sql` - Full schema with comments
- `001_quick_deploy.sql` - Minimal version for quick deployment

**Quick Setup**: Copy and paste `001_quick_deploy.sql` into your Supabase SQL Editor and run it.

#### Tables Overview

```sql
-- Books table
CREATE TABLE books (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  cover_image_url TEXT,
  description TEXT,
  isbn TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vocabulary words table
CREATE TABLE vocab_words (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE CASCADE,  -- NULL for global words
  word TEXT NOT NULL,
  definition TEXT NOT NULL,
  synonyms TEXT[] NOT NULL DEFAULT '{}',
  antonyms TEXT[] NOT NULL DEFAULT '{}',
  example_sentence TEXT DEFAULT '',
  mastered BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Study sessions table (for analytics)
CREATE TABLE study_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id UUID REFERENCES books(id) ON DELETE SET NULL,
  mode TEXT NOT NULL CHECK (mode IN ('flashcards', 'multiple_choice', 'fill_in_blank')),
  total_questions INTEGER NOT NULL DEFAULT 0,
  correct_answers INTEGER NOT NULL DEFAULT 0,
  mastered_count INTEGER NOT NULL DEFAULT 0,
  score INTEGER GENERATED ALWAYS AS (
    CASE WHEN total_questions > 0 THEN (correct_answers * 100) / total_questions ELSE 0 END
  ) STORED,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User settings table (premium status & preferences)
CREATE TABLE user_settings (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  is_premium BOOLEAN NOT NULL DEFAULT FALSE,
  subscription_product_id TEXT,
  subscription_expires_at TIMESTAMPTZ,
  last_restored_purchase TIMESTAMPTZ,
  notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  daily_reminder_time TIME DEFAULT '08:00',
  preferred_study_mode TEXT DEFAULT 'flashcards',
  feature_flags JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User profiles table (display info & stats)
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  total_books INTEGER NOT NULL DEFAULT 0,
  total_words INTEGER NOT NULL DEFAULT 0,
  mastered_words INTEGER NOT NULL DEFAULT 0,
  total_study_sessions INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security on all tables
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocab_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
```

#### Row Level Security (RLS)

All tables have RLS policies that ensure users can only access their own data:

```sql
-- Example policy for books
CREATE POLICY "Users can view their own books"
  ON books FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own books"
  ON books FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own books"
  ON books FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own books"
  ON books FOR DELETE USING (auth.uid() = user_id);
```

See the full migration files for complete policy definitions.

## Dependencies

- **[Supabase Swift SDK](https://github.com/supabase/supabase-swift)** - Authentication & database
- **[Google Mobile Ads SDK](https://github.com/googleads/swift-package-manager-google-mobile-ads)** - AdMob monetization
- **[Mixpanel Swift SDK](https://github.com/mixpanel/mixpanel-swift)** - Analytics tracking
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

-- ============================================================================
-- Read & Recall - Supabase Database Schema
-- ============================================================================
-- 
-- Complete database schema for the Read & Recall iOS app.
-- Run this migration in your Supabase SQL Editor to create all tables.
--
-- Tables:
--   - books: User's book collection
--   - vocab_words: Vocabulary words (can be linked to books or global)
--   - study_sessions: Study session history and analytics
--   - user_settings: User preferences and premium status
--
-- All tables use:
--   - UUID primary keys (matches iOS UUID type)
--   - user_id foreign key to auth.users (Supabase Auth)
--   - Timestamps with timezone
--   - Row Level Security (RLS) enabled
--
-- ============================================================================

-- Enable UUID extension (usually enabled by default in Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- BOOKS TABLE
-- ============================================================================
-- Stores user's book collection with metadata from Google Books API
-- 
-- Swift model: Book.swift
-- CodingKeys mapping:
--   id -> id
--   userId -> user_id  
--   title -> title
--   author -> author
--   coverImageUrl -> cover_image_url
--   createdAt -> created_at

CREATE TABLE IF NOT EXISTS books (
    -- Primary key: UUID generated client-side in iOS
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to Supabase Auth user
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Book metadata
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    cover_image_url TEXT,  -- URL to book cover (from Google Books API)
    
    -- Optional extended metadata (for future features)
    description TEXT,
    isbn TEXT,
    page_count INTEGER,
    published_date TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user lookups
CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);

-- Index for search functionality
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);

-- Trigger to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_books_updated_at
    BEFORE UPDATE ON books
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VOCAB_WORDS TABLE
-- ============================================================================
-- Stores vocabulary words with definitions, synonyms, antonyms
-- Words can be linked to a book or be "global" (book_id = NULL)
--
-- Swift model: VocabWord.swift
-- CodingKeys mapping:
--   id -> id
--   bookId -> book_id
--   word -> word
--   definition -> definition
--   synonyms -> synonyms
--   antonyms -> antonyms
--   exampleSentence -> example_sentence
--   mastered -> mastered
--   createdAt -> created_at

CREATE TABLE IF NOT EXISTS vocab_words (
    -- Primary key: UUID generated client-side in iOS
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to Supabase Auth user (for RLS and direct queries)
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Foreign key to books (NULL for global/unassigned words)
    -- CASCADE delete: when a book is deleted, its words are also deleted
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    
    -- Word data
    word TEXT NOT NULL,
    definition TEXT NOT NULL,
    
    -- Arrays for synonyms and antonyms
    -- PostgreSQL TEXT[] maps to Swift [String]
    synonyms TEXT[] NOT NULL DEFAULT '{}',
    antonyms TEXT[] NOT NULL DEFAULT '{}',
    
    -- Example sentence using the word
    example_sentence TEXT DEFAULT '',
    
    -- Learning status
    mastered BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast user lookups
CREATE INDEX IF NOT EXISTS idx_vocab_words_user_id ON vocab_words(user_id);

-- Index for fast book word lookups
CREATE INDEX IF NOT EXISTS idx_vocab_words_book_id ON vocab_words(book_id);

-- Index for word search
CREATE INDEX IF NOT EXISTS idx_vocab_words_word ON vocab_words(word);

-- Index for mastery filtering
CREATE INDEX IF NOT EXISTS idx_vocab_words_mastered ON vocab_words(mastered);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER update_vocab_words_updated_at
    BEFORE UPDATE ON vocab_words
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- STUDY_SESSIONS TABLE
-- ============================================================================
-- Tracks study session history for analytics and progress tracking
--
-- Swift model: StudySessionResult (StudyViewModel.swift)
-- Maps to analytics events tracked via Mixpanel

CREATE TABLE IF NOT EXISTS study_sessions (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- Foreign key to Supabase Auth user
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Optional: which book was being studied (NULL for "All Words" sessions)
    book_id UUID REFERENCES books(id) ON DELETE SET NULL,
    
    -- Study mode: 'flashcards', 'multiple_choice', 'fill_in_blank'
    mode TEXT NOT NULL CHECK (mode IN ('flashcards', 'multiple_choice', 'fill_in_blank')),
    
    -- Session results
    total_questions INTEGER NOT NULL DEFAULT 0,
    correct_answers INTEGER NOT NULL DEFAULT 0,
    mastered_count INTEGER NOT NULL DEFAULT 0,  -- Words newly mastered this session
    
    -- Computed score (percentage 0-100)
    score INTEGER GENERATED ALWAYS AS (
        CASE WHEN total_questions > 0 
             THEN (correct_answers * 100) / total_questions 
             ELSE 0 
        END
    ) STORED,
    
    -- Duration in seconds
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    
    -- When the session was completed
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for user session history
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);

-- Index for book-specific sessions
CREATE INDEX IF NOT EXISTS idx_study_sessions_book_id ON study_sessions(book_id);

-- Index for mode filtering
CREATE INDEX IF NOT EXISTS idx_study_sessions_mode ON study_sessions(mode);

-- Index for recent sessions (analytics)
CREATE INDEX IF NOT EXISTS idx_study_sessions_completed_at ON study_sessions(completed_at DESC);

-- ============================================================================
-- USER_SETTINGS TABLE
-- ============================================================================
-- Stores user preferences and subscription/premium status
-- Primary key is user_id (one settings row per user)
--
-- Swift: SubscriptionManager.swift uses @AppStorage for local persistence
-- This table syncs premium status to the backend

CREATE TABLE IF NOT EXISTS user_settings (
    -- Primary key: user_id (one row per user)
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Premium/subscription status
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Subscription details (from Apple StoreKit)
    subscription_product_id TEXT,  -- e.g., 'com.bookvocab.premium.monthly'
    subscription_expires_at TIMESTAMPTZ,
    
    -- Last time purchases were restored
    last_restored_purchase TIMESTAMPTZ,
    
    -- App preferences
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    daily_reminder_time TIME,
    preferred_study_mode TEXT DEFAULT 'flashcards',
    
    -- Feature flags (for A/B testing or gradual rollouts)
    feature_flags JSONB DEFAULT '{}',
    
    -- Whether the user has completed onboarding
    has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- USER PROFILES TABLE (OPTIONAL)
-- ============================================================================
-- Extended user profile information
-- Can be used for social features or display purposes

CREATE TABLE IF NOT EXISTS user_profiles (
    -- Primary key: user_id (one row per user)
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Display name
    display_name TEXT,
    
    -- Profile picture URL
    avatar_url TEXT,
    
    -- Stats (denormalized for quick display)
    total_books INTEGER NOT NULL DEFAULT 0,
    total_words INTEGER NOT NULL DEFAULT 0,
    mastered_words INTEGER NOT NULL DEFAULT 0,
    total_study_sessions INTEGER NOT NULL DEFAULT 0,
    
    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Trigger to auto-update updated_at timestamp
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================
-- Enable RLS on all tables to ensure users can only access their own data

-- Books RLS
ALTER TABLE books ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own books"
    ON books FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own books"
    ON books FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own books"
    ON books FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own books"
    ON books FOR DELETE
    USING (auth.uid() = user_id);

-- Vocab Words RLS
ALTER TABLE vocab_words ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own vocab words"
    ON vocab_words FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own vocab words"
    ON vocab_words FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own vocab words"
    ON vocab_words FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own vocab words"
    ON vocab_words FOR DELETE
    USING (auth.uid() = user_id);

-- Study Sessions RLS
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own study sessions"
    ON study_sessions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own study sessions"
    ON study_sessions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- No update/delete policies for study_sessions (historical data should be immutable)

-- User Settings RLS
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own settings"
    ON user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own settings"
    ON user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own settings"
    ON user_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- User Profiles RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own profile"
    ON user_profiles FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile"
    ON user_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
    ON user_profiles FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to automatically create user settings and profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Create user settings with defaults
    INSERT INTO user_settings (user_id)
    VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    
    -- Create user profile with defaults
    INSERT INTO user_profiles (user_id, display_name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email))
    ON CONFLICT (user_id) DO NOTHING;
    
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Trigger to create user settings/profile on new signup
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- Function to update user profile stats (call after adding/removing books/words)
CREATE OR REPLACE FUNCTION update_user_stats(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE user_profiles
    SET 
        total_books = (SELECT COUNT(*) FROM books WHERE user_id = p_user_id),
        total_words = (SELECT COUNT(*) FROM vocab_words WHERE user_id = p_user_id),
        mastered_words = (SELECT COUNT(*) FROM vocab_words WHERE user_id = p_user_id AND mastered = TRUE),
        total_study_sessions = (SELECT COUNT(*) FROM study_sessions WHERE user_id = p_user_id),
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE books IS 'User book collection with metadata from Google Books API';
COMMENT ON TABLE vocab_words IS 'Vocabulary words with definitions, can be linked to books or global';
COMMENT ON TABLE study_sessions IS 'Study session history for analytics and progress tracking';
COMMENT ON TABLE user_settings IS 'User preferences and premium subscription status';
COMMENT ON TABLE user_profiles IS 'Extended user profile with denormalized stats';

COMMENT ON COLUMN vocab_words.book_id IS 'NULL for global words not assigned to any book';
COMMENT ON COLUMN vocab_words.synonyms IS 'PostgreSQL array, maps to Swift [String]';
COMMENT ON COLUMN vocab_words.antonyms IS 'PostgreSQL array, maps to Swift [String]';
COMMENT ON COLUMN study_sessions.mode IS 'flashcards, multiple_choice, or fill_in_blank';
COMMENT ON COLUMN user_settings.feature_flags IS 'JSONB for A/B testing flags';

-- ============================================================================
-- SEED DATA (Optional - Uncomment to add sample data)
-- ============================================================================

/*
-- Sample book (replace USER_ID with actual auth.users id)
-- INSERT INTO books (user_id, title, author, cover_image_url)
-- VALUES (
--     'USER_ID_HERE',
--     'The Great Gatsby',
--     'F. Scott Fitzgerald',
--     'https://covers.openlibrary.org/b/id/7222246-L.jpg'
-- );

-- Sample vocab word
-- INSERT INTO vocab_words (user_id, book_id, word, definition, synonyms, antonyms, example_sentence)
-- VALUES (
--     'USER_ID_HERE',
--     'BOOK_ID_HERE',
--     'Ephemeral',
--     'Lasting for a very short time',
--     ARRAY['Fleeting', 'Transient', 'Brief'],
--     ARRAY['Permanent', 'Lasting', 'Enduring'],
--     'The ephemeral beauty of the sunset lasted only moments.'
-- );
*/

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================

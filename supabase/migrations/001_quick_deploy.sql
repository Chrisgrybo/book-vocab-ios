-- ============================================================================
-- Read & Recall - Quick Deploy Schema
-- ============================================================================
-- Copy and paste this entire file into your Supabase SQL Editor and run it.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Books table
CREATE TABLE IF NOT EXISTS books (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    cover_image_url TEXT,
    description TEXT,
    isbn TEXT,
    page_count INTEGER,
    published_date TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Vocab words table
CREATE TABLE IF NOT EXISTS vocab_words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE CASCADE,
    word TEXT NOT NULL,
    definition TEXT NOT NULL,
    synonyms TEXT[] NOT NULL DEFAULT '{}',
    antonyms TEXT[] NOT NULL DEFAULT '{}',
    example_sentence TEXT DEFAULT '',
    mastered BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Study sessions table
CREATE TABLE IF NOT EXISTS study_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES books(id) ON DELETE SET NULL,
    mode TEXT NOT NULL CHECK (mode IN ('flashcards', 'multiple_choice', 'fill_in_blank')),
    total_questions INTEGER NOT NULL DEFAULT 0,
    correct_answers INTEGER NOT NULL DEFAULT 0,
    mastered_count INTEGER NOT NULL DEFAULT 0,
    score INTEGER GENERATED ALWAYS AS (
        CASE WHEN total_questions > 0 
             THEN (correct_answers * 100) / total_questions 
             ELSE 0 
        END
    ) STORED,
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User settings table (premium status)
CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    subscription_product_id TEXT,
    subscription_expires_at TIMESTAMPTZ,
    last_restored_purchase TIMESTAMPTZ,
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    daily_reminder_time TIME,
    preferred_study_mode TEXT DEFAULT 'flashcards',
    feature_flags JSONB DEFAULT '{}',
    has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User profiles table (optional)
CREATE TABLE IF NOT EXISTS user_profiles (
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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);
CREATE INDEX IF NOT EXISTS idx_books_title ON books(title);
CREATE INDEX IF NOT EXISTS idx_vocab_words_user_id ON vocab_words(user_id);
CREATE INDEX IF NOT EXISTS idx_vocab_words_book_id ON vocab_words(book_id);
CREATE INDEX IF NOT EXISTS idx_vocab_words_word ON vocab_words(word);
CREATE INDEX IF NOT EXISTS idx_vocab_words_mastered ON vocab_words(mastered);
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_completed_at ON study_sessions(completed_at DESC);

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers
DROP TRIGGER IF EXISTS update_books_updated_at ON books;
CREATE TRIGGER update_books_updated_at BEFORE UPDATE ON books
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vocab_words_updated_at ON vocab_words;
CREATE TRIGGER update_vocab_words_updated_at BEFORE UPDATE ON vocab_words
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON user_profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security
ALTER TABLE books ENABLE ROW LEVEL SECURITY;
ALTER TABLE vocab_words ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Books policies
DROP POLICY IF EXISTS "Users can view their own books" ON books;
CREATE POLICY "Users can view their own books" ON books FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own books" ON books;
CREATE POLICY "Users can insert their own books" ON books FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own books" ON books;
CREATE POLICY "Users can update their own books" ON books FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own books" ON books;
CREATE POLICY "Users can delete their own books" ON books FOR DELETE USING (auth.uid() = user_id);

-- Vocab words policies
DROP POLICY IF EXISTS "Users can view their own vocab words" ON vocab_words;
CREATE POLICY "Users can view their own vocab words" ON vocab_words FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own vocab words" ON vocab_words;
CREATE POLICY "Users can insert their own vocab words" ON vocab_words FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own vocab words" ON vocab_words;
CREATE POLICY "Users can update their own vocab words" ON vocab_words FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own vocab words" ON vocab_words;
CREATE POLICY "Users can delete their own vocab words" ON vocab_words FOR DELETE USING (auth.uid() = user_id);

-- Study sessions policies
DROP POLICY IF EXISTS "Users can view their own study sessions" ON study_sessions;
CREATE POLICY "Users can view their own study sessions" ON study_sessions FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own study sessions" ON study_sessions;
CREATE POLICY "Users can insert their own study sessions" ON study_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User settings policies
DROP POLICY IF EXISTS "Users can view their own settings" ON user_settings;
CREATE POLICY "Users can view their own settings" ON user_settings FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own settings" ON user_settings;
CREATE POLICY "Users can insert their own settings" ON user_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own settings" ON user_settings;
CREATE POLICY "Users can update their own settings" ON user_settings FOR UPDATE USING (auth.uid() = user_id);

-- User profiles policies
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
CREATE POLICY "Users can view their own profile" ON user_profiles FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
CREATE POLICY "Users can insert their own profile" ON user_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile" ON user_profiles FOR UPDATE USING (auth.uid() = user_id);

-- Auto-create settings and profile for new users
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_settings (user_id) VALUES (NEW.id) ON CONFLICT (user_id) DO NOTHING;
    INSERT INTO user_profiles (user_id, display_name) 
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email)) 
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ language 'plpgsql' SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Update user stats function
CREATE OR REPLACE FUNCTION update_user_stats(p_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE user_profiles SET 
        total_books = (SELECT COUNT(*) FROM books WHERE user_id = p_user_id),
        total_words = (SELECT COUNT(*) FROM vocab_words WHERE user_id = p_user_id),
        mastered_words = (SELECT COUNT(*) FROM vocab_words WHERE user_id = p_user_id AND mastered = TRUE),
        total_study_sessions = (SELECT COUNT(*) FROM study_sessions WHERE user_id = p_user_id),
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$ language 'plpgsql' SECURITY DEFINER;

-- Done! Schema deployed successfully.

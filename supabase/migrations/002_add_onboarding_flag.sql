-- ============================================
-- Migration: Add has_completed_onboarding to user_settings
-- Run this in Supabase SQL Editor
-- ============================================

-- Add has_completed_onboarding column to user_settings
ALTER TABLE user_settings
ADD COLUMN IF NOT EXISTS has_completed_onboarding BOOLEAN NOT NULL DEFAULT FALSE;

-- Update existing users to mark onboarding as complete (they're existing users)
UPDATE user_settings
SET has_completed_onboarding = TRUE
WHERE has_completed_onboarding = FALSE;

-- Create an index for faster lookups
CREATE INDEX IF NOT EXISTS idx_user_settings_onboarding
ON user_settings(has_completed_onboarding)
WHERE has_completed_onboarding = FALSE;

-- Verify the column was added
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'user_settings' AND column_name = 'has_completed_onboarding';

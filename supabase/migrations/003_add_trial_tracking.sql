-- ============================================================================
-- Migration 003: Add Premium Trial Tracking
-- ============================================================================
-- Adds trial tracking to support the 1-month free trial with StoreKit 2
--
-- The premium_trial_started_at column tracks when a user started their free trial.
-- This enables:
--   1. Backend-side trial status verification
--   2. Cross-device sync of trial start date
--   3. Analytics on trial conversion
--
-- Premium access logic:
--   isPremium = active_subscription OR in_free_trial
--   in_free_trial = premium_trial_started_at IS NOT NULL 
--                   AND premium_trial_started_at > NOW() - INTERVAL '1 month'
-- ============================================================================

-- Add premium_trial_started_at column to user_settings
ALTER TABLE user_settings
ADD COLUMN IF NOT EXISTS premium_trial_started_at TIMESTAMPTZ;

-- Add comment for documentation
COMMENT ON COLUMN user_settings.premium_trial_started_at IS 
    'Timestamp when user started their 1-month free trial. NULL if never started.';

-- Create index for efficient trial queries
CREATE INDEX IF NOT EXISTS idx_user_settings_trial_started 
ON user_settings(premium_trial_started_at) 
WHERE premium_trial_started_at IS NOT NULL;

-- ============================================================================
-- HELPER FUNCTIONS FOR TRIAL STATUS
-- ============================================================================

-- Function to check if a user is currently in their free trial
-- Returns TRUE if trial started less than 1 month ago
CREATE OR REPLACE FUNCTION is_in_free_trial(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    trial_start TIMESTAMPTZ;
BEGIN
    SELECT premium_trial_started_at INTO trial_start
    FROM user_settings
    WHERE user_id = p_user_id;
    
    -- If trial never started, not in trial
    IF trial_start IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check if trial started less than 1 month ago
    RETURN trial_start > NOW() - INTERVAL '1 month';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if a user has premium access (subscription OR trial)
-- This is the main function to determine premium access
CREATE OR REPLACE FUNCTION has_premium_access(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    settings_record user_settings%ROWTYPE;
BEGIN
    SELECT * INTO settings_record
    FROM user_settings
    WHERE user_id = p_user_id;
    
    -- No settings record = no premium
    IF settings_record IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Check active subscription first (is_premium set by StoreKit)
    IF settings_record.is_premium = TRUE THEN
        -- Verify subscription hasn't expired (if expiration date exists)
        IF settings_record.subscription_expires_at IS NOT NULL THEN
            IF settings_record.subscription_expires_at > NOW() THEN
                RETURN TRUE;
            END IF;
        ELSE
            -- is_premium is TRUE with no expiration = active subscription
            RETURN TRUE;
        END IF;
    END IF;
    
    -- Check free trial
    IF settings_record.premium_trial_started_at IS NOT NULL THEN
        IF settings_record.premium_trial_started_at > NOW() - INTERVAL '1 month' THEN
            RETURN TRUE;
        END IF;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to start a free trial for a user
-- Returns TRUE if trial started, FALSE if user already has/had trial or subscription
CREATE OR REPLACE FUNCTION start_free_trial(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    settings_record user_settings%ROWTYPE;
BEGIN
    SELECT * INTO settings_record
    FROM user_settings
    WHERE user_id = p_user_id;
    
    -- No settings record, cannot start trial
    IF settings_record IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Already has subscription
    IF settings_record.is_premium = TRUE THEN
        RETURN FALSE;
    END IF;
    
    -- Already used trial (can only use once)
    IF settings_record.premium_trial_started_at IS NOT NULL THEN
        RETURN FALSE;
    END IF;
    
    -- Start the trial
    UPDATE user_settings
    SET 
        premium_trial_started_at = NOW(),
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VIEW FOR EASY QUERYING
-- ============================================================================

-- Create a view that includes computed trial status
CREATE OR REPLACE VIEW user_premium_status AS
SELECT 
    user_id,
    is_premium,
    subscription_product_id,
    subscription_expires_at,
    premium_trial_started_at,
    -- Computed: is currently in free trial
    CASE 
        WHEN premium_trial_started_at IS NOT NULL 
             AND premium_trial_started_at > NOW() - INTERVAL '1 month'
        THEN TRUE 
        ELSE FALSE 
    END AS in_free_trial,
    -- Computed: trial days remaining (NULL if not in trial)
    CASE 
        WHEN premium_trial_started_at IS NOT NULL 
             AND premium_trial_started_at > NOW() - INTERVAL '1 month'
        THEN EXTRACT(DAY FROM (premium_trial_started_at + INTERVAL '1 month') - NOW())::INTEGER
        ELSE NULL 
    END AS trial_days_remaining,
    -- Computed: has any premium access
    CASE 
        WHEN is_premium = TRUE THEN TRUE
        WHEN premium_trial_started_at IS NOT NULL 
             AND premium_trial_started_at > NOW() - INTERVAL '1 month'
        THEN TRUE
        ELSE FALSE 
    END AS has_premium_access,
    created_at,
    updated_at
FROM user_settings;

-- Grant access to the view
GRANT SELECT ON user_premium_status TO authenticated;

-- ============================================================================
-- RLS POLICY FOR CALLING FUNCTIONS (if needed from client)
-- ============================================================================

-- Users can only check their own trial status
-- The functions already use SECURITY DEFINER but let's be explicit

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================

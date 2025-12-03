//
//  Secrets.example.swift
//  BookVocab
//
//  TEMPLATE FILE - Copy this to Secrets.swift and add your credentials
//
//  Instructions:
//  1. Copy this file and rename it to "Secrets.swift"
//  2. Replace the placeholder values with your actual credentials
//  3. The Secrets.swift file is gitignored and will not be committed
//
//  Required Setup:
//  - Supabase: Create project at supabase.com
//  - Mixpanel: Create project at mixpanel.com (free tier available)
//

import Foundation

/// Contains sensitive API keys and configuration values.
/// This struct is intentionally not committed to version control.
enum Secrets {
    
    // MARK: - Supabase Configuration
    
    /// Your Supabase project URL
    /// Found at: Supabase Dashboard > Project Settings > API > Project URL
    static let supabaseUrl = "https://your-project-ref.supabase.co"
    
    /// Your Supabase anonymous/public key
    /// Found at: Supabase Dashboard > Project Settings > API > anon/public key
    static let supabaseKey = "your-supabase-anon-key"
    
    // MARK: - Mixpanel Configuration
    
    /// Your Mixpanel project token
    /// Found at: Mixpanel Dashboard > Settings > Project Settings > Project Token
    ///
    /// Setup Instructions:
    /// 1. Create a Mixpanel account at https://mixpanel.com (free tier available)
    /// 2. Create a new project for BookVocab
    /// 3. Go to Settings > Project Settings
    /// 4. Copy the "Project Token" (NOT the API Secret)
    /// 5. Paste it below
    ///
    /// Note: Events will still be queued locally if network is unavailable
    static let mixpanelToken = "your-mixpanel-token"
}

//
//  Secrets.example.swift
//  BookVocab
//
//  TEMPLATE FILE - Copy this to Secrets.swift and add your credentials
//
//  Instructions:
//  1. Copy this file and rename it to "Secrets.swift"
//  2. Replace the placeholder values with your actual Supabase credentials
//  3. The Secrets.swift file is gitignored and will not be committed
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
}


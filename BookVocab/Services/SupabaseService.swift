//
//  SupabaseService.swift
//  BookVocab
//
//  Service layer for Supabase backend integration.
//  Handles authentication, database operations, and real-time subscriptions.
//
//  This singleton provides a centralized Supabase client that can be accessed
//  throughout the app via SupabaseService.shared.client
//

import Foundation
import Auth
import PostgREST
import Supabase

/// Service class for all Supabase backend operations.
/// Implements singleton pattern for shared access across the app.
///
/// Usage:
/// ```swift
/// let client = SupabaseService.shared.client
/// let session = try await client.auth.signIn(email: email, password: password)
/// ```
class SupabaseService {
    
    // MARK: - Singleton
    
    /// Shared instance of the Supabase service.
    /// Use this to access the Supabase client throughout the app.
    static let shared = SupabaseService()
    
    // MARK: - Properties
    
    /// The Supabase client instance.
    /// This is the main entry point for all Supabase operations including:
    /// - Authentication (client.auth)
    /// - Database queries (client.from("table"))
    /// - Storage (client.storage)
    /// - Realtime subscriptions (client.realtime)
    let client: SupabaseClient
    
    // MARK: - Initialization
    
    /// Private initializer for singleton pattern.
    /// Creates and configures the Supabase client using credentials from Secrets.swift
    private init() {
        // Initialize the Supabase client with project credentials from Secrets
        // The client handles token storage, refresh, and all API communications
        //
        // Note: The Supabase SDK may show a warning about emitLocalSessionAsInitialSession.
        // This is informational about future API changes and can be safely ignored for now.
        self.client = SupabaseClient(
            supabaseURL: URL(string: Secrets.supabaseUrl)!,
            supabaseKey: Secrets.supabaseKey
        )
    }
}

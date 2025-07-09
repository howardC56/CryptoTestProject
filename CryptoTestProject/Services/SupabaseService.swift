import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private let client: SupabaseClient
    
    private init() {
        let supabaseURL = Configuration.supabaseURL
        let supabaseKey = Configuration.supabaseKey
        
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            fatalError("Supabase URL or API key not found. Please set them in Config.xcconfig")
        }
        
        self.client = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(
            email: email,
            password: password
        )
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(
            email: email,
            password: password
        )
    }
    
    @MainActor
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    @MainActor
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email)
    }
    
    @MainActor
    func getCurrentSession() async throws -> Session? {
        return try await client.auth.session
    }
    
    @MainActor
    func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
    }
} 

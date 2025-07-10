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
        
        guard let url = URL(string: supabaseURL) else {
            fatalError("Invalid Supabase URL format: \(supabaseURL)")
        }
        
        // Print the URL and key (redacted) for debugging
        print("Initializing Supabase with URL: \(url)")
        print("API Key (first 10 chars): \(String(supabaseKey.prefix(10)))...")
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
        )
    }
    
    @MainActor
    func signUp(email: String, password: String) async throws {
        do {
            try await client.auth.signUp(
                email: email,
                password: password
            )
            print("Sign up successful for email: \(email)")
        } catch {
            print("Sign up failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        do {
            print("Attempting to sign in with email: \(email)")
            try await client.auth.signIn(
                email: email,
                password: password
            )
            print("Sign in successful for email: \(email)")
        } catch {
            print("Sign in failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func signOut() async throws {
        do {
            try await client.auth.signOut()
            print("Sign out successful")
        } catch {
            print("Sign out failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func resetPassword(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email)
            print("Password reset email sent to: \(email)")
        } catch {
            print("Password reset failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func getCurrentSession() async -> Session? {
        do {
            // Use try? to handle the case where session might throw an error
            guard let session = try? await client.auth.session else {
                print("No active session found")
                return nil
            }
            print("Retrieved session successfully")
            return session
        } catch {
            print("Error getting session: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    func getCurrentUser() async -> User? {
        do {
            // Use try? to handle the case where session might throw an error
            guard let session = try? await client.auth.session else {
                print("No active session found")
                return nil
            }
            
            // Check if the user exists in the session
            return session.user
//            if let user = session.user {
//                print("Retrieved user successfully: \(user.email ?? "No email")")
//                return user
//            } else {
//                print("Session exists but no user found")
//                return nil
//            }
        } catch {
            print("Error getting user: \(error.localizedDescription)")
            return nil
        }
    }
} 

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isAuthenticated = false
    @Published var isGuestMode = false
    
    private let supabase = SupabaseService.shared
    
    init() {
        Task {
            await checkAuthState()
        }
    }
    
    func checkAuthState() async {
        print("Checking authentication state...")
        do {
            // Safely check for a user
            let user = await supabase.getCurrentUser()
            isAuthenticated = user != nil
            
            if let user = user {
                print("User is authenticated: \(user.email ?? "No email")")
                // If we have a real user, we're not in guest mode
                isGuestMode = false
            } else {
                print("No authenticated user found")
                // Ensure we're marked as not authenticated
                isAuthenticated = false
            }
        } catch {
            print("Error checking auth state: \(error.localizedDescription)")
            isAuthenticated = false
        }
    }
    
    func signUp() async {
        isLoading = true
        do {
            print("Attempting to sign up with email: \(email)")
            try await supabase.signUp(email: email, password: password)
            isGuestMode = false // Ensure we're not in guest mode after signing up
            await checkAuthState()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("Sign up error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func signIn() async {
        isLoading = true
        do {
            print("Attempting to sign in with email: \(email)")
            try await supabase.signIn(email: email, password: password)
            isGuestMode = false // Ensure we're not in guest mode after signing in
            await checkAuthState()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("Sign in error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        do {
            if isGuestMode {
                // Just exit guest mode without calling signOut API
                isGuestMode = false
                print("Exited guest mode")
            } else {
                // Normal sign out for authenticated users
                print("Attempting to sign out")
                try await supabase.signOut()
            }
            isAuthenticated = false
            print("Sign out successful, isAuthenticated set to false")
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("Sign out error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func resetPassword() async {
        isLoading = true
        do {
            print("Attempting to reset password for email: \(email)")
            try await supabase.resetPassword(email: email)
            print("Password reset email sent")
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("Reset password error: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func continueAsGuest() {
        isGuestMode = true
        isAuthenticated = true
        print("Continuing as guest, isGuestMode: \(isGuestMode), isAuthenticated: \(isAuthenticated)")
    }
}

import Foundation

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isAuthenticated = false
    
    private let supabase = SupabaseService.shared
    
    init() {
        Task {
            await checkAuthState()
        }
    }
    
    func checkAuthState() async {
        do {
            let user = try await supabase.getCurrentUser()
            isAuthenticated = user != nil
        } catch {
            isAuthenticated = false
        }
    }
    
    func signUp() async {
        isLoading = true
        do {
            try await supabase.signUp(email: email, password: password)
            await checkAuthState()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signIn() async {
        isLoading = true
        do {
            try await supabase.signIn(email: email, password: password)
            await checkAuthState()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signOut() async {
        isLoading = true
        do {
            try await supabase.signOut()
            isAuthenticated = false
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func resetPassword() async {
        isLoading = true
        do {
            try await supabase.resetPassword(email: email)
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
} 
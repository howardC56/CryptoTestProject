import SwiftUI

struct AuthView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AuthViewModel
    @State private var isSignUp = false
    @State private var emailOffset: CGFloat = 1000
    @State private var passwordOffset: CGFloat = 1200
    @State private var buttonOffset: CGFloat = 1400
    @State private var showForgotPassword = false
    
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.1, blue: 0.2),
            Color(red: 0.15, green: 0.15, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
                .ignoresSafeArea()
            
            // Content
            VStack(spacing: 25) {
                // Header
                Text(isSignUp ? "Create Account" : "Welcome Back")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                // Form Fields
                VStack(spacing: 20) {
                    // Email Field
                    CustomTextField(
                        text: $viewModel.email,
                        placeholder: "Email",
                        systemImage: "envelope.fill"
                    )
                    .offset(x: emailOffset)
                    
                    // Password Field
                    CustomTextField(
                        text: $viewModel.password,
                        placeholder: "Password",
                        systemImage: "lock.fill",
                        isSecure: true
                    )
                    .offset(x: passwordOffset)
                }
                .padding(.horizontal, 30)
                
                // Forgot Password
                if !isSignUp {
                    Button("Forgot Password?") {
                        showForgotPassword = true
                    }
                    .foregroundColor(.gray)
                    .font(.system(size: 14, weight: .medium))
                }
                
                // Action Button
                Button(action: {
                    Task {
                        // Ensure we're not in guest mode when signing in/up
                        viewModel.isGuestMode = false
                        
                        if isSignUp {
                            await viewModel.signUp()
                        } else {
                            await viewModel.signIn()
                        }
                        if viewModel.isAuthenticated {
                            dismiss()
                        }
                    }
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.7, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                            .frame(height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))
                        }
                    }
                }
                .disabled(viewModel.isLoading)
                .padding(.horizontal, 30)
                .offset(x: buttonOffset)
                
                // Toggle Sign In/Up
                HStack {
                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                        .foregroundColor(.gray)
                    Button(isSignUp ? "Sign In" : "Sign Up") {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                            isSignUp.toggle()
                        }
                    }
                    .foregroundColor(.white)
                }
                .font(.system(size: 14, weight: .medium))
                
                Spacer()
            }
            .padding(.top, 50)
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1)) {
                emailOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                passwordOffset = 0
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                buttonOffset = 0
            }
        }
        .onChange(of: viewModel.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                dismiss()
            }
        }
    }
}

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let systemImage: String
    var isSecure: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundColor(.gray)
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .tint(.white)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.2)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Text("Reset Password")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                CustomTextField(
                    text: $viewModel.email,
                    placeholder: "Email",
                    systemImage: "envelope.fill"
                )
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await viewModel.resetPassword()
                        dismiss()
                    }
                }) {
                    Text("Send Reset Link")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.3, green: 0.7, blue: 1.0),
                                    Color(red: 0.5, green: 0.3, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel())
} 
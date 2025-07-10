import SwiftUI

struct SplashView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var logoScale: CGFloat = 0.1
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    @State private var rotation: Double = 0
    @State private var showAuth = false
    
    private let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.05, green: 0.05, blue: 0.15),
            Color(red: 0.1, green: 0.1, blue: 0.2)
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
            VStack(spacing: 40) {
                Spacer()
                
                // Logo
                ZStack {
                    // Outer circle with gradient
                    Circle()
                        .fill(
                            AngularGradient(
                                colors: [.blue, .purple, .pink, .blue],
                                center: .center
                            )
                        )
                        .frame(width: 180, height: 180)
                        .rotationEffect(.degrees(rotation))
                        .blur(radius: 5)
                    
                    // Inner circle with dark background
                    Circle()
                        .fill(Color(red: 0.08, green: 0.08, blue: 0.18))
                        .frame(width: 160, height: 160)
                    
                    // Crypto symbol
                    Image(systemName: "bitcoinsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white)
                        .shadow(color: .blue.opacity(0.8), radius: 10, x: 0, y: 0)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // Title
                Text("CryptoTracker")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(titleOpacity)
                    .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 0)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 20) {
                    // Sign In Button
                    Button {
                        showAuth = true
                    } label: {
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
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            
                            Text("Sign In To Access All Features")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                    
                    // Continue as Guest Button
                    Button {
                        authViewModel.continueAsGuest()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.clear)
                                .frame(height: 60)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    Color(red: 0.6, green: 0.6, blue: 0.7),
                                                    Color(red: 0.3, green: 0.3, blue: 0.4)
                                                ],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                            
                            Text("Continue as Guest")
                                .foregroundColor(.white)
                                .font(.system(size: 18, weight: .semibold))
                        }
                    }
                }
                .padding(.horizontal, 30)
                .opacity(buttonsOpacity)
                
                Spacer()
                    .frame(height: 50)
            }
        }
        .sheet(isPresented: $showAuth) {
            AuthView(viewModel: authViewModel)
        }
        .onAppear {
            // Animate logo
            withAnimation(.spring(response: 1.2, dampingFraction: 0.6).delay(0.3)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            
            // Animate title
            withAnimation(.easeInOut(duration: 1.0).delay(1.0)) {
                titleOpacity = 1.0
            }
            
            // Animate buttons
            withAnimation(.easeInOut(duration: 1.0).delay(1.5)) {
                buttonsOpacity = 1.0
            }
            
            // Continuous rotation animation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

#Preview {
    SplashView(authViewModel: AuthViewModel())
} 

import SwiftUI

struct GradientLoginButton: View {
    @State private var rotationAngle: Double = 0
    @State private var showAuth = false
    @ObservedObject var viewModel: AuthViewModel
    
    private let gradientColors: [Color] = [
        .blue,
        .purple,
        .pink
    ]
    
    private let borderColors: [Color] = [
        Color(red: 0.3, green: 0.7, blue: 1.0),
        Color(red: 0.8, green: 0.3, blue: 1.0),
        Color(red: 1.0, green: 0.5, blue: 0.5),
        Color(red: 0.3, green: 0.7, blue: 1.0)
    ]
    
    var body: some View {
        Button {
            Task {
                if viewModel.isAuthenticated {
                    if viewModel.isGuestMode {
                        // Show sign in sheet instead of signing out when in guest mode
                        showAuth = true
                    } else {
                        await viewModel.signOut()
                    }
                } else {
                    showAuth = true
                }
            }
        } label: {
            Text(buttonText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    ZStack {
                        // Static background gradient
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        
                        // Rotating border with blur effect
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                AngularGradient(
                                    colors: borderColors,
                                    center: .center,
                                    angle: .degrees(rotationAngle)
                                ),
                                lineWidth: 2
                            )
                            .blur(radius: 0.5) // Subtle blur for a glowing effect
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .sheet(isPresented: $showAuth) {
            AuthView(viewModel: viewModel)
        }
        .onAppear {
            withAnimation(
                .linear(duration: 3)
                .repeatForever(autoreverses: false)
            ) {
                rotationAngle = 360
            }
        }
    }
    
    private var buttonText: String {
        if viewModel.isAuthenticated {
            return viewModel.isGuestMode ? "Sign In" : "Sign Out"
        } else {
            return "Sign In"
        }
    }
}

#Preview {
    GradientLoginButton(viewModel: AuthViewModel())
        .frame(width: 100, height: 40)
        .preferredColorScheme(.dark)
} 

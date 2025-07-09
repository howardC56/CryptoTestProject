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
                    await viewModel.signOut()
                } else {
                    showAuth = true
                }
            }
        } label: {
            Text(viewModel.isAuthenticated ? "Sign Out" : "Login")
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
}

#Preview {
    GradientLoginButton(viewModel: AuthViewModel())
        .frame(width: 100, height: 40)
        .preferredColorScheme(.dark)
} 
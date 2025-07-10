import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @Namespace private var tabAnimation
    @State private var gradientPosition: CGFloat = 0
    
    // Tab item model
    struct TabItem {
        let icon: String
        let title: String
        let tag: Int
    }
    
    // Define tab items
    private let tabItems = [
        TabItem(icon: "dollarsign.circle.fill", title: "Crypto", tag: 0),
        TabItem(icon: "gamecontroller.fill", title: "Checkers", tag: 1),
        TabItem(icon: "crown.fill", title: "Chess", tag: 2)
    ]
    
    // Silver gradient colors
    private let silverGradientColors = [
        Color(red: 0.8, green: 0.8, blue: 0.85),
        Color(red: 0.95, green: 0.95, blue: 0.97),
        Color(red: 0.75, green: 0.75, blue: 0.8),
        Color(red: 0.9, green: 0.9, blue: 0.95),
        Color(red: 0.8, green: 0.8, blue: 0.85)
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabItems, id: \.tag) { item in
                TabButton(
                    icon: item.icon,
                    title: item.title,
                    isSelected: selectedTab == item.tag,
                    namespace: tabAnimation,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = item.tag
                        }
                    }
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 8)
        .padding(.bottom, getSafeAreaBottom())
        .background(
            // Animated silver gradient background
            LinearGradient(
                gradient: Gradient(colors: silverGradientColors),
                startPoint: UnitPoint(x: gradientPosition, y: 0),
                endPoint: UnitPoint(x: gradientPosition + 1, y: 1)
            )
            .animation(
                Animation.linear(duration: 3)
                    .repeatForever(autoreverses: false),
                value: gradientPosition
            )
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    gradientPosition = 1.0
                }
            }
            .overlay(
                // Glass effect overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
        )
        .frame(height: 60) // Standard height
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -3)
    }
    
    // Get safe area bottom padding
    private func getSafeAreaBottom() -> CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }
}

// Individual tab button
struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // Icon with animation
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color(red: 0.3, green: 0.7, blue: 1.0),
                                        Color(red: 0.5, green: 0.3, blue: 1.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .matchedGeometryEffect(id: "background", in: namespace)
                    }
                    
                    Image(systemName: icon)
                        .font(.system(size: isSelected ? 22 : 18))
                        .foregroundColor(isSelected ? .white : Color(red: 0.3, green: 0.3, blue: 0.35))
                        .frame(height: 22)
                        .scaleEffect(isSelected ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                
                // Title
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Color(red: 0.3, green: 0.3, blue: 0.35) : Color(red: 0.5, green: 0.5, blue: 0.55))
                    .opacity(isSelected ? 1 : 0.7)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// UIKit blur view for iOS
struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(0))
        }
    }
} 
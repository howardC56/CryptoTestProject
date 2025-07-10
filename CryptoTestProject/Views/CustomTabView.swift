import SwiftUI

struct CustomTabView<Content: View>: View {
    @Binding var selectedTab: Int
    @ViewBuilder let content: (Int) -> Content
    
    // Get safe area bottom padding
    private var safeAreaBottom: CGFloat {
        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .map { $0 as? UIWindowScene }
            .compactMap { $0 }
            .first?.windows
            .filter { $0.isKeyWindow }
            .first
        
        return keyWindow?.safeAreaInsets.bottom ?? 0
    }
    
    // Standard tab bar height
    private let tabBarHeight: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content area
            content(selectedTab)
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .safeAreaInset(edge: .bottom) {
                    // Add spacing for the tab bar (height + safe area)
                    Color.clear.frame(height: tabBarHeight + safeAreaBottom)
                }
            
            // Custom tab bar - positioned at the very bottom
            CustomTabBar(selectedTab: $selectedTab)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    CustomTabView(selectedTab: .constant(0)) { tab in
        switch tab {
        case 0:
            ZStack {
                Color.red
                Text("Crypto Tab")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        case 1:
            ZStack {
                Color.blue
                Text("Checkers Tab")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        case 2:
            ZStack {
                Color.green
                Text("Chess Tab")
                    .foregroundColor(.white)
                    .font(.largeTitle)
            }
        default:
            Color.gray
        }
    }
} 
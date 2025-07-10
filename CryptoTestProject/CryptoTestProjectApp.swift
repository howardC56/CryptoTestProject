//
//  CryptoTestProjectApp.swift
//  CryptoTestProject
//
//  Created by Howard Chang on 7/7/25.
//

import SwiftUI

@main
struct CryptoTestProjectApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @State private var hasSeenSplash = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenSplash {
                    SplashView(authViewModel: authViewModel)
                        .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
                            if isAuthenticated {
                                withAnimation {
                                    hasSeenSplash = true
                                }
                            }
                        }
                } else {
                    ContentView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}

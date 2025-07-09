//
//  ContentView.swift
//  CryptoTestProject
//
//  Created by Howard Chang on 7/7/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = CryptoViewModel()
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                // Show tab bar when authenticated
                MainTabView(
                    cryptoViewModel: viewModel,
                    authViewModel: authViewModel
                )
            } else {
                // Show only crypto view without tab bar when not authenticated
                NavigationView {
                    CryptoTabView(viewModel: viewModel, authViewModel: authViewModel)
                }
            }
        }
        .task {
            await viewModel.fetchCryptos()
            await authViewModel.checkAuthState()
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
    }
}

struct MainTabView: View {
    @ObservedObject var cryptoViewModel: CryptoViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Crypto tab
            NavigationView {
                CryptoTabView(viewModel: cryptoViewModel, authViewModel: authViewModel)
            }
            .tabItem {
                Label("Crypto", systemImage: "dollarsign.circle.fill")
            }
            .tag(0)
            
            // Checkers tab
            CheckersView()
                .tabItem {
                    Label("Checkers", systemImage: "gamecontroller.fill")
                }
                .tag(1)
            
            // Chess tab
            ChessView()
                .tabItem {
                    Label("Chess", systemImage: "crown.fill")
                }
                .tag(2)
        }
        .onAppear {
            // Force refresh crypto data when tab view appears
            Task {
                await cryptoViewModel.refresh()
            }
            
            // Customize tab bar appearance
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            
            // Create gradient colors for the tab bar
            let lightGray = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
            let mediumGray = UIColor(red: 0.9, green: 0.9, blue: 0.92, alpha: 1.0)
            
            // Create gradient layer
            let gradientLayer = CAGradientLayer()
            gradientLayer.colors = [lightGray.cgColor, mediumGray.cgColor]
            gradientLayer.locations = [0.0, 1.0]
            
            // Create an image from the gradient layer
            UIGraphicsBeginImageContextWithOptions(CGSize(width: UIScreen.main.bounds.width, height: 100), false, 0.0)
            if let context = UIGraphicsGetCurrentContext() {
                gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 100)
                gradientLayer.render(in: context)
                let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Set the gradient image as the tab bar background
                tabBarAppearance.backgroundImage = gradientImage
            }
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
}

struct CryptoTabView: View {
    @ObservedObject var viewModel: CryptoViewModel
    @ObservedObject var authViewModel: AuthViewModel
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cryptos.isEmpty {
                VStack {
                    ProgressView("Loading cryptocurrencies...")
                        .progressViewStyle(.circular)
                        .padding()
                    
                    Button("Retry") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 20)
                }
            } else if let error = viewModel.error {
                VStack {
                    Text("Error loading data")
                        .foregroundColor(.red)
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding()
            } else if viewModel.cryptos.isEmpty {
                VStack {
                    Text("No cryptocurrencies available")
                        .font(.headline)
                    
                    Button("Refresh") {
                        Task {
                            await viewModel.refresh()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.top, 20)
                }
            } else {
                List(viewModel.cryptos) { crypto in
                    NavigationLink {
                        CryptoDetailView(viewModel: CryptoDetailViewModel(crypto: crypto))
                    } label: {
                        CryptoRowView(crypto: crypto)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.refresh()
                }
            }
        }
        .navigationTitle("Watchlist")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                GradientLoginButton(viewModel: authViewModel)
                    .frame(width: 100, height: 36)
            }
        }
        .onAppear {
            if viewModel.cryptos.isEmpty {
                Task {
                    await viewModel.fetchCryptos()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}

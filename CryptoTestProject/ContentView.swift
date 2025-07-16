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
    @EnvironmentObject var authViewModel: AuthViewModel
    
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
        CustomTabView(selectedTab: $selectedTab) { tab in
            switch tab {
            case 0:
            // Crypto tab
            NavigationView {
                CryptoTabView(viewModel: cryptoViewModel, authViewModel: authViewModel)
            }
            case 1:
            // Checkers tab
            CheckersView()
            case 2:
            // Chess tab
            ChessView()
            default:
                EmptyView()
            }
        }
        .onChange(of: selectedTab) { newTab in
            if newTab == 0 {
                // User navigated to crypto tab, start updates
                print("📱 Navigated to Crypto tab - starting updates")
                cryptoViewModel.startUpdates()
            } else {
                // User navigated away from crypto tab, stop updates
                print("📱 Navigated away from Crypto tab - stopping updates")
                cryptoViewModel.stopUpdates()
                }
        }
        .onAppear {
            // When the tab view appears, only start updates if on crypto tab
            if selectedTab == 0 {
                print("📱 MainTabView appeared with Crypto tab selected - starting updates")
                cryptoViewModel.startUpdates()
            }
        }
        .onDisappear {
            // When the tab view disappears, stop updates
            print("📱 MainTabView disappeared - stopping updates")
            cryptoViewModel.stopUpdates()
        }
    }
}

struct CryptoTabView: View {
    @ObservedObject var viewModel: CryptoViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @State private var isRefreshing = false
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.cryptos.isEmpty {
                VStack {
                    ProgressView("Loading cryptocurrencies...")
                        .progressViewStyle(.circular)
                        .padding()
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
                    isRefreshing = true
                    await viewModel.refresh()
                    isRefreshing = false
                }
            }
        }
        .navigationTitle("Crypto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                GradientLoginButton(viewModel: authViewModel)
                    .frame(width: 100, height: 36)
            }
        }
        .onAppear {
            // Start updates when the crypto tab view appears
            print("📱 CryptoTabView appeared - starting updates")
            viewModel.startUpdates()
        }
        .onDisappear {
            // Stop updates when the crypto tab view disappears
            print("📱 CryptoTabView disappeared - stopping updates")
            viewModel.stopUpdates()
        }
        // Update isRefreshing state when auto-refresh happens
        .onChange(of: viewModel.refreshTrigger) { _ in
            withAnimation {
                isRefreshing = true
                
                // Hide the indicator after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    withAnimation {
                        isRefreshing = false
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}

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
        .onAppear {
            // Force refresh crypto data when tab view appears
            Task {
                await cryptoViewModel.refresh()
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
        .environmentObject(AuthViewModel())
}

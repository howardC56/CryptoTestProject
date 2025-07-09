import Foundation
import Combine

@MainActor
class CryptoViewModel: ObservableObject {
    @Published var cryptos: [Crypto] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let service = CoinGeckoService()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 120 // 2 minutes in seconds
    
    nonisolated init() {
        // Initialize without starting the timer
        // Timer will be started in onAppear
    }
    
    deinit {
        Task { @MainActor in
            stopAutoRefresh()
        }
    }
    
    @objc private func refreshTimerFired() {
        Task { @MainActor in
            await fetchCryptos()
        }
    }
    
    func setupAutoRefresh() {
        // Cancel any existing timer
        stopAutoRefresh()
        
        // Create a new timer that fires every 2 minutes
        refreshTimer = Timer.scheduledTimer(
            timeInterval: refreshInterval,
            target: self,
            selector: #selector(refreshTimerFired),
            userInfo: nil,
            repeats: true
        )
    }
    
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    func fetchCryptos() async {
        isLoading = true
        error = nil
        
        do {
            let cryptos = try await service.fetchTopCryptos()
            self.cryptos = cryptos
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    // Call this when the view appears
    func onAppear() {
        Task {
            await fetchCryptos()
        }
        setupAutoRefresh() // Ensure timer is running
    }
    
    // Call this when the view disappears
    func onDisappear() {
        stopAutoRefresh()
    }
    
    // Call this for manual refresh
    func refresh() async {
        await fetchCryptos()
    }
} 
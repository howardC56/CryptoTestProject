import Foundation
import Combine

@MainActor
class CryptoViewModel: ObservableObject {
    @Published var cryptos: [Crypto] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var refreshTrigger = false  // Simple boolean to trigger refresh animations
    
    private let service = CoinGeckoService()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 10 // 10 seconds
    
    nonisolated init() {
        // Initialize without starting the timer
        // Timer will be started in onAppear
    }
    
    deinit {
        // Store in a local variable to avoid capturing self in the dispatch
        let timer = refreshTimer
        
        // Dispatch to main queue since we're potentially not on the main thread
        DispatchQueue.main.async {
            timer?.invalidate()
        }
    }
    
    @objc private func refreshTimerFired() {
        Task { @MainActor in
            await refreshCryptoData()
        }
    }
    
    func setupAutoRefresh() {
        // Cancel any existing timer
        stopAutoRefresh()
        
        // Create a new timer that fires every 10 seconds
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
        // Don't show loading indicator for background refreshes
        let showLoading = cryptos.isEmpty
        if showLoading {
            isLoading = true
        }
        error = nil
        
        do {
            let cryptos = try await service.fetchTopCryptos()
            self.cryptos = cryptos
            // Toggle the refresh trigger to notify views that data has been updated
            self.refreshTrigger.toggle()
        } catch {
            self.error = error
        }
        
        if showLoading {
            isLoading = false
        }
    }
    
    // New method to refresh crypto data while preserving logo and title
    func refreshCryptoData() async {
        // Only proceed if we have existing data
        guard !cryptos.isEmpty else {
            await fetchCryptos()
            return
        }
        
        error = nil
        
        do {
            print("🔄 Refreshing crypto data while preserving logos and titles")
            let updatedCryptos = try await service.refreshCryptoData(existingCryptos: cryptos)
            self.cryptos = updatedCryptos
            // Toggle the refresh trigger to notify views that data has been updated
            self.refreshTrigger.toggle()
            print("✅ Successfully refreshed crypto data")
        } catch {
            print("❌ Error refreshing crypto data: \(error)")
            self.error = error
        }
    }
    
    // Call this when the view appears
    func onAppear() {
        Task {
            if cryptos.isEmpty {
                await fetchCryptos()
            } else {
                await refreshCryptoData()
            }
        }
        setupAutoRefresh() // Ensure timer is running
    }
    
    // Call this when the view disappears
    func onDisappear() {
        stopAutoRefresh()
    }
    
    // Call this for manual refresh
    func refresh() async {
        await refreshCryptoData()
    }
} 

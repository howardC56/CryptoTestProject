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
        // Timer will be started when needed
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
        
        print("⏱️ Auto-refresh timer started")
    }
    
    func stopAutoRefresh() {
        if refreshTimer != nil {
            refreshTimer?.invalidate()
            refreshTimer = nil
            print("⏱️ Auto-refresh timer stopped")
        }
    }
    
    // Start updates - fetch data and setup auto-refresh
    func startUpdates() {
        print("🔄 Starting crypto updates")
        Task {
            if cryptos.isEmpty {
                await fetchCryptos()
            } else {
                await refreshCryptoData()
            }
        }
        setupAutoRefresh()
    }
    
    // Stop updates - cancel auto-refresh
    func stopUpdates() {
        print("🛑 Stopping crypto updates")
        stopAutoRefresh()
    }
    
    func fetchCryptos() async {
        // Don't show loading indicator for background refreshes
        let showLoading = cryptos.isEmpty
        if showLoading {
            isLoading = true
        }
        error = nil
        
        do {
            print("🔄 Fetching crypto data from API")
            let cryptos = try await service.fetchTopCryptos()
            self.cryptos = cryptos
            // Toggle the refresh trigger to notify views that data has been updated
            self.refreshTrigger.toggle()
            print("✅ Successfully fetched crypto data")
        } catch {
            print("❌ Error fetching crypto data: \(error)")
            self.error = error
        }
        
        if showLoading {
            isLoading = false
        }
    }
    
    // Refresh crypto data while preserving logo and title
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
    
    // Legacy methods - now just delegate to the new methods
    func onAppear() {
        startUpdates()
    }
    
    func onDisappear() {
        stopUpdates()
    }
    
    // Call this for manual refresh
    func refresh() async {
        await refreshCryptoData()
    }
} 

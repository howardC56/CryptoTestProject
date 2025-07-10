import Foundation
import SwiftUI
import Combine

@MainActor
class CryptoDetailViewModel: ObservableObject {
    @Published var cryptoDetail: CoinGeckoService.CryptoDetail?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var candleData: [CandleData] = []
    @Published var selectedTimeRange: TimeRange = .day
    @Published var refreshTrigger = false  // Trigger for animations
    
    let crypto: Crypto
    private let service = CoinGeckoService()
    private var refreshTimer: Timer.TimerPublisher?
    private var timerCancellable: AnyCancellable?
    
    init(crypto: Crypto) {
        self.crypto = crypto
        setupRefreshTimer()
    }
    
    deinit {
        // Immediately cancel the timer subscription to prevent memory leaks
        // Store in a local variable to avoid capturing self in the dispatch
        let cancellable = timerCancellable
        
        // Dispatch to main queue since we're potentially not on the main thread
        DispatchQueue.main.async {
            cancellable?.cancel()
        }
    }
    
    private func setupRefreshTimer() {
        refreshTimer = Timer.publish(every: 10, on: .main, in: .common)
        timerCancellable = refreshTimer?
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshPrice()
                }
            }
    }
    
    private func stopRefreshTimer() {
        // This function is already isolated to the main actor because of the class annotation
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    func refreshPrice() async {
        // Don't show loading indicator for background refreshes
        error = nil
        
        print("🔄 Refreshing price for \(crypto.id)")
        
        do {
            // Fetch new detail data
            let detailResult = try await service.fetchCryptoDetail(id: crypto.id)
            print("✅ Successfully refreshed price data")
            
            // Create a new detail object with updated data
            let updatedDetail = detailResult
            
            // Always update the detail object to ensure UI refreshes
            self.cryptoDetail = updatedDetail
            
            // Only refresh candle data if we're looking at short timeframes
            if selectedTimeRange == .day || selectedTimeRange == .week {
                let candleResult = try await service.fetchOHLCV(id: crypto.id, days: selectedTimeRange.days)
                
                // Always update candle data to ensure UI refreshes
                self.candleData = candleResult
            }
            
            // Always toggle the trigger to notify views that data has been updated
            self.refreshTrigger.toggle()
            print("🔄 UI refresh triggered")
        } catch {
            print("❌ Error refreshing price: \(error)")
            self.error = error
        }
    }
    
    // Helper method to compare candle arrays
    private func areCandleArraysEqual(_ array1: [CandleData], _ array2: [CandleData]) -> Bool {
        guard array1.count == array2.count else { return false }
        
        // Compare each element
        for i in 0..<array1.count {
            if array1[i] != array2[i] {
                return false
            }
        }
        
        return true
    }
    
    func fetchCryptoDetail() async {
        isLoading = true
        error = nil
        
        print("🔄 Fetching crypto detail for \(crypto.id)")
        
        do {
            async let detail = service.fetchCryptoDetail(id: crypto.id)
            async let candles = service.fetchOHLCV(id: crypto.id, days: selectedTimeRange.days)
            
            let (detailResult, candleResult) = try await (detail, candles)
            print("✅ Successfully fetched crypto detail and \(candleResult.count) candles")
            
            self.cryptoDetail = detailResult
            self.candleData = candleResult
            self.refreshTrigger.toggle() // Trigger animation on initial load
        } catch {
            print("❌ Error fetching crypto detail: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    var minPrice: Double {
        candleData.map { $0.low }.min() ?? 0
    }
    
    var maxPrice: Double {
        candleData.map { $0.high }.max() ?? 0
    }
} 

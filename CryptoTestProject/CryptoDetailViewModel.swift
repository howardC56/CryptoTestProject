import Foundation
import SwiftUI

@MainActor
class CryptoDetailViewModel: ObservableObject {
    @Published var cryptoDetail: CoinGeckoService.CryptoDetail?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var candleData: [CandleData] = []
    @Published var selectedTimeRange: TimeRange = .day
    
    let crypto: Crypto
    private let service = CoinGeckoService()
    
    init(crypto: Crypto) {
        self.crypto = crypto
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

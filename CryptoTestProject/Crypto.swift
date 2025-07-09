import Foundation

struct Crypto: Identifiable, Codable {
    let id: String
    let symbol: String
    let name: String
    let image: String
    let currentPrice: Double
    let priceChangePercentage24h: Double
    let sparklineIn7D: SparklineData
    
    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case name
        case image
        case currentPrice = "current_price"
        case priceChangePercentage24h = "price_change_percentage_24h"
        case sparklineIn7D = "sparkline_in_7d"
    }
}

struct SparklineData: Codable {
    let price: [Double]
}

extension Crypto {
    static let mockData = Crypto(
        id: "bitcoin",
        symbol: "btc",
        name: "Bitcoin",
        image: "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
        currentPrice: 50000.0,
        priceChangePercentage24h: 5.5,
        sparklineIn7D: SparklineData(price: [
            45000, 46000, 47000, 48000, 49000, 50000
        ])
    )
} 

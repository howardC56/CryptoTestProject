import Foundation

enum CoinGeckoError: Error {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKey
    case invalidCandleData
}

struct CandleData: Identifiable, Equatable {
    let id: UUID
    let timestamp: Double
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    init?(from array: [Double]) {
        guard array.count >= 5 else {
            print("⚠️ Invalid array count: \(array.count)")
            return nil
        }
        
        self.id = UUID()
        self.timestamp = array[0]
        self.open = array[1]
        self.high = array[2]
        self.low = array[3]
        self.close = array[4]
        // Volume is not provided in OHLC data, set to 0
        self.volume = 0
    }
    
    // Direct initializer for creating mock data
    init(timestamp: Double, open: Double, high: Double, low: Double, close: Double, volume: Double) {
        self.id = UUID()
        self.timestamp = timestamp
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
    
    // Implement Equatable
    static func == (lhs: CandleData, rhs: CandleData) -> Bool {
        // Compare all relevant fields except id (which is randomly generated)
        return lhs.timestamp == rhs.timestamp &&
               lhs.open == rhs.open &&
               lhs.high == rhs.high &&
               lhs.low == rhs.low &&
               lhs.close == rhs.close &&
               lhs.volume == rhs.volume
    }
}

// Extension for mock data
extension CandleData {
    static var mockData: [CandleData] {
        let now = Date().timeIntervalSince1970 * 1000 // Convert to milliseconds
        let hourInMillis = 3600.0 * 1000.0
        
        return [
            CandleData(timestamp: now - (hourInMillis * 4), open: 45000, high: 46000, low: 44800, close: 45800, volume: 1200000),
            CandleData(timestamp: now - (hourInMillis * 3), open: 45800, high: 47000, low: 45600, close: 46500, volume: 1500000),
            CandleData(timestamp: now - (hourInMillis * 2), open: 46500, high: 46800, low: 45900, close: 46200, volume: 1100000),
            CandleData(timestamp: now - hourInMillis, open: 46200, high: 47500, low: 46000, close: 47200, volume: 1800000),
            CandleData(timestamp: now, open: 47200, high: 48000, low: 47000, close: 47800, volume: 2000000)
        ]
    }
}

actor CoinGeckoService {
    struct CryptoDetail: Codable {
        let id: String
        let symbol: String
        let name: String
        let market_data: MarketData
        
        struct MarketData: Codable {
            let current_price: [String: Double]
            let market_cap: [String: Double]
            let total_volume: [String: Double]
            let circulating_supply: Double?
            let price_change_percentage_24h: Double?
        }
    }
    
    private let baseURL = "https://api.coingecko.com/api/v3"
    private let session: URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        let apiKey = Configuration.coinGeckoAPIKey
        
        guard !apiKey.isEmpty else {
            fatalError("CoinGecko API key not found. Please set it in Config.xcconfig")
        }
        
        print("🔑 Using CoinGecko API key: \(apiKey.prefix(8))...")
        
        config.httpAdditionalHeaders = [
            "x-cg-demo-api-key": apiKey
        ]
        self.session = URLSession(configuration: config)
    }
    
    func fetchTopCryptos(currency: String = "usd", perPage: Int = 20) async throws -> [Crypto] {
        let endpoint = "/coins/markets"
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: currency),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "sparkline", value: "true")
        ]
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw CoinGeckoError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CoinGeckoError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let cryptos = try JSONDecoder().decode([Crypto].self, from: data)
                return cryptos
            case 401:
                throw CoinGeckoError.invalidResponse
            case 429:
                throw CoinGeckoError.invalidResponse
            default:
                throw CoinGeckoError.invalidResponse
            }
        } catch let error as DecodingError {
            throw CoinGeckoError.decodingError(error)
        } catch {
            throw CoinGeckoError.networkError(error)
        }
    }
    
    func fetchCryptoDetail(id: String) async throws -> CryptoDetail {
        let endpoint = "/coins/\(id)"
        let queryItems = [
            URLQueryItem(name: "localization", value: "false"),
            URLQueryItem(name: "tickers", value: "false"),
            URLQueryItem(name: "market_data", value: "true"),
            URLQueryItem(name: "community_data", value: "false"),
            URLQueryItem(name: "developer_data", value: "false"),
            URLQueryItem(name: "sparkline", value: "false")
        ]
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw CoinGeckoError.invalidURL
        }
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CoinGeckoError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let detail = try JSONDecoder().decode(CryptoDetail.self, from: data)
                return detail
            case 401:
                throw CoinGeckoError.invalidResponse
            case 429:
                throw CoinGeckoError.invalidResponse
            default:
                throw CoinGeckoError.invalidResponse
            }
        } catch let error as DecodingError {
            throw CoinGeckoError.decodingError(error)
        } catch {
            throw CoinGeckoError.networkError(error)
        }
    }
    
    func fetchOHLCV(id: String, days: Int = 1, currency: String = "usd") async throws -> [CandleData] {
        let endpoint = "/coins/\(id)/ohlc"
        let queryItems = [
            URLQueryItem(name: "vs_currency", value: currency),
            URLQueryItem(name: "days", value: String(days))
        ]
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            throw CoinGeckoError.invalidURL
        }
        
        print("🔍 Fetching OHLCV data from: \(url)")
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CoinGeckoError.invalidResponse
            }
            
            print("📡 OHLCV Response status: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                let rawData = try JSONDecoder().decode([[Double]].self, from: data)
                print("📊 Received \(rawData.count) candles")
                
                // Print first candle data for debugging
                if let firstCandle = rawData.first {
                    print("📊 First candle data: \(firstCandle)")
                }
                
                let candleData = rawData.compactMap(CandleData.init)
                print("📈 Processed \(candleData.count) valid candles")
                
                guard !candleData.isEmpty else {
                    print("⚠️ No valid candle data found")
                    throw CoinGeckoError.invalidCandleData
                }
                
                return candleData.sorted { $0.timestamp < $1.timestamp }
                
            case 401:
                print("❌ Authentication failed")
                throw CoinGeckoError.invalidResponse
            case 429:
                print("⚠️ Rate limit exceeded")
                throw CoinGeckoError.invalidResponse
            default:
                print("❌ Unexpected status code: \(httpResponse.statusCode)")
                throw CoinGeckoError.invalidResponse
            }
        } catch let error as DecodingError {
            print("🚫 Decoding error: \(error)")
            throw CoinGeckoError.decodingError(error)
        } catch {
            print("🚫 Network error: \(error)")
            throw CoinGeckoError.networkError(error)
        }
    }
    
    func refreshCryptoData(existingCryptos: [Crypto]) async throws -> [Crypto] {
        // Get fresh data from API
        let freshCryptos = try await fetchTopCryptos()
        
        // Create a dictionary of existing cryptos by ID for quick lookup
        let existingDict = Dictionary(uniqueKeysWithValues: existingCryptos.map { ($0.id, $0) })
        
        // Map fresh data while preserving logo and name from existing data
        return freshCryptos.map { freshCrypto in
            if let existingCrypto = existingDict[freshCrypto.id] {
                // Create a new crypto object with:
                // - Preserved logo (image) and name from existing data
                // - Updated price, change percentage, and sparkline data from fresh data
                return Crypto(
                    id: freshCrypto.id,
                    symbol: freshCrypto.symbol,
                    name: existingCrypto.name,  // Preserve name
                    image: existingCrypto.image, // Preserve image
                    currentPrice: freshCrypto.currentPrice, // Update price
                    priceChangePercentage24h: freshCrypto.priceChangePercentage24h, // Update change
                    sparklineIn7D: freshCrypto.sparklineIn7D // Update sparkline
                )
            } else {
                // If it's a new crypto not in the existing list, use it as is
                return freshCrypto
            }
        }
    }
} 

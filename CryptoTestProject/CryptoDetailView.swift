import SwiftUI

// MARK: - Formatters
private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    static let percentage: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Price Header View
struct PriceHeaderView: View {
    let detail: CoinGeckoService.CryptoDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NumberFormatter.currency.string(from: NSNumber(value: detail.market_data.current_price["usd"] ?? 0)) ?? "")
                .font(.system(size: 32, weight: .bold))
            
            HStack {
                let priceChange = detail.market_data.price_change_percentage_24h ?? 0
                Text(NumberFormatter.percentage.string(from: NSNumber(value: priceChange / 100)) ?? "")
                    .foregroundColor(priceChange >= 0 ? .green : .red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (priceChange >= 0 ? Color.green : Color.red)
                            .opacity(0.2)
                            .cornerRadius(6)
                    )
                Text("24h")
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

// MARK: - Crypto Header View
struct CryptoHeaderView: View {
    let crypto: Crypto
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: crypto.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 32, height: 32)
            
            Text(crypto.name)
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Market Stats View
struct MarketStatsView: View {
    let detail: CoinGeckoService.CryptoDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Stats")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 16) {
                StatRowView(
                    title: "Market Cap",
                    value: NumberFormatter.currency.string(from: NSNumber(value: detail.market_data.market_cap["usd"] ?? 0)) ?? ""
                )
                
                StatRowView(
                    title: "Volume (24h)",
                    value: NumberFormatter.currency.string(from: NSNumber(value: detail.market_data.total_volume["usd"] ?? 0)) ?? ""
                )
                
                StatRowView(
                    title: "Circulating Supply",
                    value: NumberFormatter.decimal.string(from: NSNumber(value: detail.market_data.circulating_supply ?? 0)) ?? ""
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
        .padding(.horizontal)
    }
}

struct StatRowView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
    }
}

// MARK: - Time Range Selector View
struct TimeRangeSelectorView: View {
    let selectedRange: TimeRange
    let onRangeSelected: (TimeRange) async -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TimeRange.allCases) { range in
                    Button {
                        Task {
                            await onRangeSelected(range)
                        }
                    } label: {
                        Text(range.rawValue)
                            .frame(width: 44)
                            .padding(.vertical, 8)
                            .background(
                                selectedRange == range ?
                                    Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundColor(
                                selectedRange == range ?
                                    .white : .primary
                            )
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Chart View Container
struct ChartContainer: View {
    let isLoading: Bool
    let error: Error?
    let candleData: [CandleData]
    let minPrice: Double
    let maxPrice: Double
    let onRetry: () async -> Void
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(height: 300)
            } else if let error = error {
                VStack(spacing: 8) {
                    Text("Failed to load chart data")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.gray)
                    Button("Try Again") {
                        Task {
                            await onRetry()
                        }
                    }
                }
                .frame(height: 300)
            } else if !candleData.isEmpty {
                CandlestickChartView(
                    data: candleData,
                    minPrice: minPrice,
                    maxPrice: maxPrice
                )
                .frame(height: 300)
                .padding(.horizontal, 5)
            } else {
                Text("No chart data available")
                    .foregroundColor(.gray)
                    .frame(height: 300)
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 10)
    }
}

// MARK: - Main View
struct CryptoDetailView: View {
    @StateObject var viewModel: CryptoDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CryptoHeaderView(crypto: viewModel.crypto)
                
                if let detail = viewModel.cryptoDetail {
                    PriceHeaderView(detail: detail)
                    
                    TimeRangeSelectorView(
                        selectedRange: viewModel.selectedTimeRange,
                        onRangeSelected: { range in
                            viewModel.selectedTimeRange = range
                            await viewModel.fetchCryptoDetail()
                        }
                    )
                    
                    ChartContainer(
                        isLoading: viewModel.isLoading,
                        error: viewModel.error,
                        candleData: viewModel.candleData,
                        minPrice: viewModel.minPrice,
                        maxPrice: viewModel.maxPrice,
                        onRetry: viewModel.fetchCryptoDetail
                    )
                    .padding(.bottom, 20) // Add extra padding to prevent chart cutoff
                    
                    MarketStatsView(detail: detail)
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchCryptoDetail()
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    CryptoDetailView(viewModel: CryptoDetailViewModel(crypto: Crypto.mockData))
        .preferredColorScheme(.dark)
} 

import SwiftUI

// MARK: - Formatters
private extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter
    }()
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

// MARK: - Main View
struct CryptoDetailView: View {
    @StateObject var viewModel: CryptoDetailViewModel
    @State private var flashUpdate = false
    
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
                            Task {
                                await viewModel.fetchCryptoDetail()
                            }
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: flashUpdate ? 1.5 : 0)
                            .opacity(flashUpdate ? 0.7 : 0)
                    )
                    
                    MarketStatsView(detail: detail)
                        .contentTransition(.opacity)
                        .animation(.easeInOut, value: detail.market_data.market_cap["usd"])
                }
            }
            .padding(.vertical)
        }
        .onAppear {
            Task {
                await viewModel.fetchCryptoDetail()
            }
        }
        .onChange(of: viewModel.refreshTrigger) { _ in
            // Flash update animation
            withAnimation(.easeInOut(duration: 0.3)) {
                flashUpdate = true
            }
            
            // Reset animation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation {
                    flashUpdate = false
                }
            }
        }
        .navigationTitle(viewModel.crypto.name)
        .navigationBarTitleDisplayMode(.inline)
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

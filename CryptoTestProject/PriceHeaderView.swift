import SwiftUI

struct PriceHeaderView: View {
    let detail: CoinGeckoService.CryptoDetail
    @State private var animatePrice: Bool = false
    
    private var currentPrice: Double {
        detail.market_data.current_price["usd"] ?? 0
    }
    
    private var priceChange: Double {
        detail.market_data.price_change_percentage_24h ?? 0
    }
    
    private var priceColor: Color {
        if priceChange > 0 {
            return .green
        } else if priceChange < 0 {
            return .red
        }
        return .primary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Price with animation
            Text(NumberFormatter.currency.string(from: NSNumber(value: currentPrice)) ?? "")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(priceColor)
                .id("price-\(UUID())") // Force view refresh when price changes
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(animatePrice ? priceColor.opacity(0.1) : Color.clear)
                )
            
            HStack {
                let changeColor = priceChange >= 0 ? Color.green : Color.red
                
                // Price change percentage with animation
                Text(NumberFormatter.percentage.string(from: NSNumber(value: priceChange / 100)) ?? "")
                    .foregroundColor(.white)
                    .id("change-\(UUID())") // Force view refresh when price change updates
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(changeColor)
                            .opacity(animatePrice ? 0.8 : 0.6)
                    )
                    .scaleEffect(animatePrice ? 1.05 : 1.0)
                
                Text("24h")
                    .foregroundColor(.gray)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
        .onAppear {
            animatePrice = false
        }
        .onChange(of: detail.market_data.current_price["usd"]) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatePrice = true
            }
            
            // Reset animation after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation {
                    animatePrice = false
                }
            }
        }
    }
}

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
} 
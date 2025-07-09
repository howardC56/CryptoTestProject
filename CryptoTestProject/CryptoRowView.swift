import SwiftUI

struct CryptoRowView: View {
    let crypto: Crypto
    
    var changeColor: Color {
        if crypto.priceChangePercentage24h > 0 {
            return .green
        } else if crypto.priceChangePercentage24h < 0 {
            return .red
        } else {
            return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: crypto.image)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                ProgressView()
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(crypto.name)
                    .font(.headline)
                Text(crypto.symbol.uppercased())
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            MiniLineChart(prices: crypto.sparklineIn7D.price, lineColor: changeColor)
                .frame(width: 60, height: 24)
                .animation(.easeInOut(duration: 0.3), value: crypto.sparklineIn7D.price)
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", crypto.currentPrice))
                    .font(.headline)
                    .contentTransition(.numericText(value: crypto.currentPrice))
                    .animation(.spring(duration: 0.5, bounce: 0.2), value: crypto.currentPrice)
                Text(String(format: "%+.2f%%", crypto.priceChangePercentage24h))
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(changeColor)
                    .cornerRadius(6)
                    .contentTransition(.numericText(value: crypto.priceChangePercentage24h))
                    .animation(.spring(duration: 0.5, bounce: 0.2), value: crypto.priceChangePercentage24h)
            }
        }
        .padding(.vertical, 8)
    }
} 
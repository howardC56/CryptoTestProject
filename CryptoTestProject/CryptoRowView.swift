import SwiftUI

struct CryptoRowView: View {
    let crypto: Crypto
    @State private var isUpdating = false
    
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
                .id("chart-\(crypto.id)-\(UUID())")
            VStack(alignment: .trailing) {
                Text(String(format: "$%.2f", crypto.currentPrice))
                    .font(.headline)
                    .id("price-\(crypto.id)-\(UUID())")
                    .onChange(of: crypto.currentPrice) { _ in
                        flashPrice()
                    }
                Text(String(format: "%+.2f%%", crypto.priceChangePercentage24h))
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(changeColor)
                    .cornerRadius(6)
                    .id("change-\(crypto.id)-\(UUID())")
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isUpdating ? changeColor.opacity(0.1) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.5), value: isUpdating)
    }
    
    private func flashPrice() {
        isUpdating = true
        
        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isUpdating = false
        }
    }
} 

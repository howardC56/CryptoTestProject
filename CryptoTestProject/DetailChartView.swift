import SwiftUI

struct DetailChartView: View {
    let prices: [Double]
    var lineColor: Color = .blue
    
    private var normalizedPrices: [CGFloat] {
        guard let min = prices.min(), let max = prices.max(), max > min else {
            return prices.map { _ in 0.5 }
        }
        return prices.map { CGFloat(($0 - min) / (max - min)) }
    }
    
    private var minPrice: Double {
        prices.min() ?? 0
    }
    
    private var maxPrice: Double {
        prices.max() ?? 0
    }
    
    private func priceLabel(_ price: Double) -> String {
        if price >= 1000 {
            return String(format: "$%.2fK", price / 1000)
        } else if price >= 1 {
            return String(format: "$%.2f", price)
        } else {
            return String(format: "$%.4f", price)
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Price indicators
                VStack(alignment: .leading, spacing: 0) {
                    Text(priceLabel(maxPrice))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(priceLabel((maxPrice + minPrice) / 2))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(priceLabel(minPrice))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(width: 60)
                
                HStack(spacing: 0) {
                    // Spacer for price labels
                    Color.clear.frame(width: 60)
                    
                    // Chart
                    ZStack {
                        // Grid lines
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(0..<5) { i in
                                Color.gray.opacity(0.1)
                                    .frame(height: 1)
                                    .frame(maxWidth: .infinity)
                                if i < 4 {
                                    Spacer()
                                }
                            }
                        }
                        
                        // Price chart
                        Path { path in
                            for (i, value) in normalizedPrices.enumerated() {
                                let x = (geo.size.width - 60) * CGFloat(i) / CGFloat(normalizedPrices.count - 1)
                                let y = geo.size.height * (1 - value)
                                
                                if i == 0 {
                                    path.move(to: CGPoint(x: x + 60, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x + 60, y: y))
                                }
                            }
                        }
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        
                        // Gradient under the line
                        Path { path in
                            // Move to bottom-left
                            path.move(to: CGPoint(x: 60, y: geo.size.height))
                            
                            // Add line to first data point
                            let firstY = geo.size.height * (1 - normalizedPrices[0])
                            path.addLine(to: CGPoint(x: 60, y: firstY))
                            
                            // Add lines through all data points
                            for (i, value) in normalizedPrices.enumerated() {
                                let x = (geo.size.width - 60) * CGFloat(i) / CGFloat(normalizedPrices.count - 1)
                                let y = geo.size.height * (1 - value)
                                path.addLine(to: CGPoint(x: x + 60, y: y))
                            }
                            
                            // Add line to bottom-right
                            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                        }
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [lineColor.opacity(0.2), lineColor.opacity(0.05)]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                }
            }
        }
    }
} 
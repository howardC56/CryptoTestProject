import SwiftUI

struct MiniLineChart: View {
    let prices: [Double]
    var lineColor: Color = .gray
    
    var normalizedPrices: [CGFloat] {
        guard let min = prices.min(), let max = prices.max(), max > min else {
            return prices.map { _ in 0.5 }
        }
        return prices.map { CGFloat(($0 - min) / (max - min)) }
    }
    
    var body: some View {
        GeometryReader { geo in
            Path { path in
                for (i, value) in normalizedPrices.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(normalizedPrices.count - 1)
                    let y = geo.size.height * (1 - value)
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(lineColor, lineWidth: 2)
            .animation(.easeInOut(duration: 0.3), value: prices)
        }
        .frame(height: 24)
    }
} 
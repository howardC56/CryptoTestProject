import SwiftUI

struct CandlestickView: View {
    let high: CGFloat
    let low: CGFloat
    let open: CGFloat
    let close: CGFloat
    let width: CGFloat
    let isGreen: Bool
    
    var body: some View {
        ZStack {
            // Vertical line from high to low
            Rectangle()
                .frame(width: 1, height: abs(high - low))
                .position(x: width / 2, y: (high + low) / 2)
                .foregroundColor(isGreen ? .green : .red)
            
            // Body rectangle from open to close
            Rectangle()
                .frame(width: width, height: abs(open - close))
                .position(x: width / 2, y: (open + close) / 2)
                .foregroundColor(isGreen ? .green : .red)
        }
        .frame(width: width)
    }
} 
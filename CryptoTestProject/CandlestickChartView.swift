import SwiftUI

// MARK: - Chart Constants
private struct ChartConstants {
    static let gridLines = 6
    static let candleSpacing: CGFloat = 2
    static let yAxisWidth: CGFloat = 60
    static let xAxisHeight: CGFloat = 30
    static let chartPadding: CGFloat = 5 // Changed to 5 for consistent spacing
    static let yAxisLabelSpacing: CGFloat = 5 // Added for y-axis label spacing
}

// MARK: - Price Axis View
private struct PriceAxisView: View {
    let availableHeight: CGFloat
    let paddedPriceRange: (min: Double, max: Double)
    let priceFormatter: NumberFormatter
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach((0...ChartConstants.gridLines).reversed(), id: \.self) { i in
                let price = paddedPriceRange.min + (Double(i) / Double(ChartConstants.gridLines)) * (paddedPriceRange.max - paddedPriceRange.min)
                Text(priceFormatter.string(from: NSNumber(value: price)) ?? "")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .frame(width: ChartConstants.yAxisWidth, alignment: .trailing)
                    .frame(height: availableHeight / CGFloat(ChartConstants.gridLines))
            }
        }
        .padding(.trailing, ChartConstants.yAxisLabelSpacing)
    }
}

// MARK: - Date Axis View
private struct DateAxisView: View {
    let availableWidth: CGFloat
    let labels: [String]
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: ChartConstants.yAxisWidth + ChartConstants.yAxisLabelSpacing)
            
            HStack(spacing: 0) {
                ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                    Text(label)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .frame(width: availableWidth / CGFloat(labels.count))
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, ChartConstants.chartPadding)
        }
        .frame(height: ChartConstants.xAxisHeight)
    }
}

// MARK: - Main Chart View
struct CandlestickChartView: View {
    let data: [CandleData]
    let minPrice: Double
    let maxPrice: Double
    
    private var paddedPriceRange: (min: Double, max: Double) {
        let range = maxPrice - minPrice
        let padding = range * 0.04
        return (
            min: max(0, minPrice - padding),
            max: maxPrice + padding
        )
    }
    
    private let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    private func getDateLabels() -> [String] {
        guard !data.isEmpty else { return [] }
        let count = data.count
        let step = max(count / 4, 1) // Changed from 3 to 4 for better distribution
        var indices = [0] // Always include first index
        indices.append(contentsOf: stride(from: step, to: count - step, by: step))
        indices.append(count - 1) // Always include last index
        
        return indices.map { index in
            let date = Date(timeIntervalSince1970: TimeInterval(data[index].timestamp / 1000))
            return dateFormatter.string(from: date)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width - ChartConstants.yAxisWidth - ChartConstants.chartPadding * 2
            let availableHeight = geometry.size.height - ChartConstants.xAxisHeight - ChartConstants.chartPadding * 2
            let candleWidth = max(1, (availableWidth - CGFloat(data.count - 1) * ChartConstants.candleSpacing) / CGFloat(max(1, data.count)))
            
            VStack(spacing: 0) {
                HStack(alignment: .top, spacing: 0) {
                    PriceAxisView(
                        availableHeight: availableHeight,
                        paddedPriceRange: paddedPriceRange,
                        priceFormatter: priceFormatter
                    )
                    
                    // Chart area
                    ZStack(alignment: .topLeading) {
                        // Grid lines
                        VStack(spacing: availableHeight / CGFloat(ChartConstants.gridLines)) {
                            ForEach(0...ChartConstants.gridLines, id: \.self) { _ in
                                Divider()
                                    .foregroundColor(Color.gray.opacity(0.2))
                            }
                        }
                        
                        // Candlesticks
                        HStack(spacing: ChartConstants.candleSpacing) {
                            ForEach(Array(data.enumerated()), id: \.element.id) { index, candle in
                                let priceRange = paddedPriceRange.max - paddedPriceRange.min
                                let high = ((candle.high - paddedPriceRange.min) / priceRange) * availableHeight
                                let low = ((candle.low - paddedPriceRange.min) / priceRange) * availableHeight
                                let open = ((candle.open - paddedPriceRange.min) / priceRange) * availableHeight
                                let close = ((candle.close - paddedPriceRange.min) / priceRange) * availableHeight
                                
                                CandlestickView(
                                    high: availableHeight - high,
                                    low: availableHeight - low,
                                    open: availableHeight - open,
                                    close: availableHeight - close,
                                    width: candleWidth,
                                    isGreen: candle.close >= candle.open
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(width: availableWidth, height: availableHeight)
                    .padding(.trailing, ChartConstants.chartPadding)
                }
                .padding(.top, ChartConstants.chartPadding)
                
                DateAxisView(
                    availableWidth: availableWidth,
                    labels: getDateLabels()
                )
            }
            .padding(.leading, ChartConstants.chartPadding)
            .frame(height: 350)
        }
    }
}

struct CandleStick: View {
    let data: CandleData
    let minPrice: Double
    let maxPrice: Double
    let width: CGFloat
    
    private var priceRange: Double { maxPrice - minPrice }
    
    private func calculateY(_ price: Double) -> CGFloat {
        let percentage = 1 - (price - minPrice) / priceRange
        return CGFloat(percentage)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let isPositive = data.close >= data.open
            let color = isPositive ? Color.green : Color.red
            
            // Wick
            Rectangle()
                .fill(color)
                .frame(
                    width: 1,
                    height: height * abs(calculateY(data.high) - calculateY(data.low))
                )
                .position(
                    x: width / 2,
                    y: height * (calculateY(data.high) + calculateY(data.low)) / 2
                )
            
            // Body
            Rectangle()
                .fill(color)
                .frame(
                    width: width,
                    height: max(1, height * abs(calculateY(data.open) - calculateY(data.close)))
                )
                .position(
                    x: width / 2,
                    y: height * (calculateY(data.open) + calculateY(data.close)) / 2
                )
        }
    }
}

#Preview {
    let mockData = CandleData.mockData
    return CandlestickChartView(
        data: mockData,
        minPrice: (mockData.map { $0.low }.min() ?? 0) * 0.99,
        maxPrice: (mockData.map { $0.high }.max() ?? 0) * 1.01
    )
    .frame(height: 400)
    .padding()
    .preferredColorScheme(.dark)
} 
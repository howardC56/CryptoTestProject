import SwiftUI

// MARK: - Chart View Container
struct ChartContainer: View {
    let isLoading: Bool
    let error: Error?
    let candleData: [CandleData]
    let minPrice: Double
    let maxPrice: Double
    let onRetry: () async -> Void
    
    @State private var animateChart: Bool = false
    
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
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(animateChart ? 0.05 : 0))
                )
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
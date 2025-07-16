import SwiftUI
// Import the model files
import Foundation

// Single square view component
struct CheckerSquareView: View {
    let row: Int
    let col: Int
    let squareState: SquareState
    let isSelected: Bool
    let lightColor: Color
    let darkColor: Color
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill((row + col) % 2 == 0 ? lightColor : darkColor)
            
            if squareState != .empty {
                Circle()
                    .fill(squareState.color)
                    .padding(8)
                
                // Show crown for king pieces
                if squareState.isKing {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                }
            }
            
            // Highlight selected piece
            if isSelected {
                Rectangle()
                    .stroke(Color.yellow, lineWidth: 3)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// Game board component
struct CheckersBoardView: View {
    @ObservedObject var gameModel: CheckersGameModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        CheckerSquareView(
                            row: row,
                            col: col,
                            squareState: gameModel.board[row][col],
                            isSelected: gameModel.selectedPiece.map { $0 == (row, col) } ?? false,
                            lightColor: Color(red: 0.9, green: 0.9, blue: 0.8), // Cream color for light squares
                            darkColor: Color(red: 0.4, green: 0.2, blue: 0.1)  // Brown color for dark squares
                        )
                        .onTapGesture {
                            gameModel.handleTap(row: row, col: col)
                        }
                    }
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

// Game status view
struct GameStatusView: View {
    @ObservedObject var gameModel: CheckersGameModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Turn: \(gameModel.isRedTurn ? "Red (You)" : "Black" + (gameModel.aiDifficulty != .none ? " (AI)" : ""))")
                    .foregroundColor(gameModel.isRedTurn ? .red : .black)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                if gameModel.isAIThinking {
                    HStack {
                        Text("AI thinking")
                            .foregroundColor(.black)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                    }
                }
            }
            
            HStack {
                Text("Red: \(gameModel.redPiecesCount)")
                    .foregroundColor(.red)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                Text("Black: \(gameModel.blackPiecesCount)")
                    .foregroundColor(.black)
                    .fontWeight(.bold)
                
                Spacer()
                
                if gameModel.gameInProgress {
                    Text("Game mode: \(gameModel.aiDifficulty == .none ? "2 Players" : "vs AI")")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
    }
}

// Winner announcement view
struct WinnerView: View {
    let winner: PieceType
    
    var body: some View {
        Text("\(winner == .red ? "Red" : "Black") Wins!")
            .font(.title)
            .fontWeight(.bold)
            .foregroundColor(winner == .red ? .red : .black)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .shadow(radius: 5)
    }
}

// Game options modal view
struct GameOptionsModalView: View {
    @ObservedObject var gameModel: CheckersGameModel
    @State private var selectedMode: AIDifficulty = .none
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Game Mode")
                .font(.title)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 15) {
                Button(action: {
                    selectedMode = .none
                }) {
                    HStack {
                        Image(systemName: selectedMode == .none ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMode == .none ? .blue : .gray)
                        
                        VStack(alignment: .leading) {
                            Text("2 Players")
                                .font(.headline)
                            Text("Play against a friend on the same device")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
                
                Button(action: {
                    selectedMode = .medium
                }) {
                    HStack {
                        Image(systemName: selectedMode == .medium ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMode == .medium ? .blue : .gray)
                        
                        VStack(alignment: .leading) {
                            Text("Play vs AI")
                                .font(.headline)
                            Text("Play against a medium difficulty AI")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                }
            }
            .padding(.vertical)
            
            Button(action: {
                gameModel.aiDifficulty = selectedMode
                gameModel.startNewGame()
            }) {
                Text("Start Game")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .padding(.horizontal, 30)
        .onAppear {
            // Set the initial selected mode to match the current game model
            selectedMode = gameModel.aiDifficulty
        }
    }
}

// Main checkers view
struct CheckersView: View {
    @StateObject private var gameModel = CheckersGameModel()
    
    // Checkerboard background colors
    private let boardBackgroundColor = Color(red: 0.0, green: 0.4, blue: 0.0) // Dark green
    
    var body: some View {
        ZStack {
            // Background
            boardBackgroundColor
                .ignoresSafeArea()
            
            VStack {
                // Game status
                GameStatusView(gameModel: gameModel)
                
                // Checkerboard
                CheckersBoardView(gameModel: gameModel)
                
                // Reset button
                Button(action: { gameModel.resetGame() }) {
                    Text("New Game")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(15)
                }
                .padding(.bottom, 5) // Reduced bottom padding
                
                Spacer(minLength: 0) // Flexible spacer to push content up
            }
            
            // Winner alert - positioned as an overlay so it stays centered
            if let winner = gameModel.winner {
                WinnerView(winner: winner)
                    .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            }
            
            // Game options modal
            if gameModel.showGameOptionsModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        GameOptionsModalView(gameModel: gameModel)
                    )
            }
        }
    }
}

#Preview {
    CheckersView()
} 
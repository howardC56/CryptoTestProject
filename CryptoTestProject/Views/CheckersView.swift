import SwiftUI

// Game piece states
enum SquareState {
    case empty
    case red
    case black
    case redKing
    case blackKing
    
    var color: Color {
        switch self {
        case .empty:
            return .clear
        case .red, .redKing:
            return .red
        case .black, .blackKing:
            return .black
        }
    }
    
    var isKing: Bool {
        self == .redKing || self == .blackKing
    }
}

// Piece types for winner determination
enum PieceType {
    case red
    case black
}

// Game model to hold state and logic
class CheckersGameModel: ObservableObject {
    @Published var board = Array(repeating: Array(repeating: SquareState.empty, count: 8), count: 8)
    @Published var selectedPiece: (Int, Int)? = nil
    @Published var isRedTurn = true
    @Published var redPiecesCount = 12
    @Published var blackPiecesCount = 12
    @Published var winner: PieceType? = nil
    
    // Constants
    let darkSquareColor = Color(red: 0.2, green: 0.1, blue: 0.3)
    let lightSquareColor = Color(red: 0.8, green: 0.8, blue: 0.9)
    
    init() {
        resetGame()
    }
    
    // Initialize the game board
    func resetGame() {
        board = Array(repeating: Array(repeating: .empty, count: 8), count: 8)
        
        // Place black pieces (top of board)
        for row in 0..<3 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    board[row][col] = .black
                }
            }
        }
        
        // Place red pieces (bottom of board)
        for row in 5..<8 {
            for col in 0..<8 {
                if (row + col) % 2 == 1 {
                    board[row][col] = .red
                }
            }
        }
        
        selectedPiece = nil
        isRedTurn = true
        redPiecesCount = 12
        blackPiecesCount = 12
        winner = nil
    }
    
    // Handle tapping on a square
    func handleTap(row: Int, col: Int) {
        // If there's already a winner, don't allow moves
        if winner != nil {
            return
        }
        
        // If a piece is already selected
        if let (selectedRow, selectedCol) = selectedPiece {
            // If tapping on the same piece, deselect it
            if selectedRow == row && selectedCol == col {
                selectedPiece = nil
                return
            }
            
            // Try to move the selected piece
            if isValidMove(from: (selectedRow, selectedCol), to: (row, col)) {
                movePiece(from: (selectedRow, selectedCol), to: (row, col))
                selectedPiece = nil
                
                // Check for winner
                if redPiecesCount == 0 {
                    winner = .black
                } else if blackPiecesCount == 0 {
                    winner = .red
                }
                
                return
            }
        }
        
        // Select a piece if it's the player's turn
        let currentPiece = board[row][col]
        if (isRedTurn && (currentPiece == .red || currentPiece == .redKing)) ||
           (!isRedTurn && (currentPiece == .black || currentPiece == .blackKing)) {
            selectedPiece = (row, col)
        }
    }
    
    // Check if a move is valid
    func isValidMove(from: (Int, Int), to: (Int, Int)) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Must move to an empty square
        if board[toRow][toCol] != .empty {
            return false
        }
        
        // Must move diagonally
        if abs(toRow - fromRow) != abs(toCol - fromCol) {
            return false
        }
        
        let piece = board[fromRow][fromCol]
        
        // Regular pieces can only move forward (unless they're kings)
        if piece == .red && toRow >= fromRow && piece != .redKing {
            return false
        }
        
        if piece == .black && toRow <= fromRow && piece != .blackKing {
            return false
        }
        
        // Can move 1 square diagonally
        if abs(toRow - fromRow) == 1 && abs(toCol - fromCol) == 1 {
            return true
        }
        
        // Can jump over opponent's piece
        if abs(toRow - fromRow) == 2 && abs(toCol - fromCol) == 2 {
            let jumpedRow = (fromRow + toRow) / 2
            let jumpedCol = (fromCol + toCol) / 2
            let jumpedPiece = board[jumpedRow][jumpedCol]
            
            // Red can jump over black
            if (piece == .red || piece == .redKing) && (jumpedPiece == .black || jumpedPiece == .blackKing) {
                return true
            }
            
            // Black can jump over red
            if (piece == .black || piece == .blackKing) && (jumpedPiece == .red || jumpedPiece == .redKing) {
                return true
            }
        }
        
        return false
    }
    
    // Move a piece on the board
    func movePiece(from: (Int, Int), to: (Int, Int)) {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Move the piece
        var piece = board[fromRow][fromCol]
        board[fromRow][fromCol] = .empty
        
        // Check if piece should be promoted to king
        if piece == .red && toRow == 0 {
            piece = .redKing
        } else if piece == .black && toRow == 7 {
            piece = .blackKing
        }
        
        board[toRow][toCol] = piece
        
        // If it was a jump, remove the jumped piece
        if abs(toRow - fromRow) == 2 {
            let jumpedRow = (fromRow + toRow) / 2
            let jumpedCol = (fromCol + toCol) / 2
            
            let jumpedPiece = board[jumpedRow][jumpedCol]
            if jumpedPiece == .red || jumpedPiece == .redKing {
                redPiecesCount -= 1
            } else if jumpedPiece == .black || jumpedPiece == .blackKing {
                blackPiecesCount -= 1
            }
            
            board[jumpedRow][jumpedCol] = .empty
        }
        
        // Switch turns
        isRedTurn.toggle()
    }
}

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
        HStack {
            Text("Turn: \(gameModel.isRedTurn ? "Red" : "Black")")
                .foregroundColor(gameModel.isRedTurn ? .red : .black)
                .font(.headline)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Red: \(gameModel.redPiecesCount)")
                .foregroundColor(.red)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            Text("Black: \(gameModel.blackPiecesCount)")
                .foregroundColor(.black)
                .fontWeight(.bold)
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
        }
    }
}

#Preview {
    CheckersView()
} 
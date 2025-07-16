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

// AI difficulty levels
enum AIDifficulty {
    case none
    case medium
}

// Game model to hold state and logic
class CheckersGameModel: ObservableObject {
    @Published var board = Array(repeating: Array(repeating: SquareState.empty, count: 8), count: 8)
    @Published var selectedPiece: (Int, Int)? = nil
    @Published var isRedTurn = true
    @Published var redPiecesCount = 12
    @Published var blackPiecesCount = 12
    @Published var winner: PieceType? = nil
    @Published var aiDifficulty: AIDifficulty = .none
    @Published var isAIThinking = false
    @Published var gameInProgress = false
    @Published var showGameOptionsModal = false
    
    // Constants
    let darkSquareColor = Color(red: 0.2, green: 0.1, blue: 0.3)
    let lightSquareColor = Color(red: 0.8, green: 0.8, blue: 0.9)
    
    init() {
        // Show game options modal on initial load
        showGameOptionsModal = true
    }
    
    // Initialize the game board
    func resetGame() {
        // Show options modal when resetting the game
        showGameOptionsModal = true
        gameInProgress = false
    }
    
    // Start a new game with the selected options
    func startNewGame() {
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
        gameInProgress = true
        showGameOptionsModal = false
        
        // If AI is enabled and it's black's turn, make an AI move
        if !isRedTurn && aiDifficulty != .none {
            makeAIMove()
        }
    }
    
    // Set AI difficulty
    func setAIDifficulty(_ difficulty: AIDifficulty) {
        self.aiDifficulty = difficulty
        // If it's already AI's turn, make a move
        if !isRedTurn && aiDifficulty != .none && gameInProgress {
            makeAIMove()
        }
    }
    
    // Handle tapping on a square
    func handleTap(row: Int, col: Int) {
        // If there's already a winner or game not in progress, don't allow moves
        if winner != nil || !gameInProgress {
            return
        }
        
        // If it's AI's turn, don't allow player to move
        if !isRedTurn && aiDifficulty != .none {
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
            if CheckersGameLogic.isValidMove(for: self, from: (selectedRow, selectedCol), to: (row, col)) {
                movePiece(from: (selectedRow, selectedCol), to: (row, col))
                selectedPiece = nil
                
                // Check for winner
                checkForWinner()
                
                // If it's now AI's turn, make an AI move
                if !isRedTurn && aiDifficulty != .none && winner == nil {
                    makeAIMove()
                }
                
                return
            }
        }
        
        // Select a piece if it's the player's turn
        let currentPiece = board[row][col]
        if (isRedTurn && (currentPiece == .red || currentPiece == .redKing)) ||
           (!isRedTurn && (currentPiece == .black || currentPiece == .blackKing) && aiDifficulty == .none) {
            selectedPiece = (row, col)
        }
    }
    
    // Move a piece on the board - delegate to CheckersGameLogic
    func movePiece(from: (Int, Int), to: (Int, Int)) {
        CheckersGameLogic.movePiece(for: self, from: from, to: to)
    }
    
    // Check for a winner - delegate to CheckersGameLogic
    func checkForWinner() {
        CheckersGameLogic.checkForWinner(for: self)
    }
    
    // Make an AI move - delegate to CheckersAI
    func makeAIMove() {
        CheckersAI.makeAIMove(for: self)
    }
} 
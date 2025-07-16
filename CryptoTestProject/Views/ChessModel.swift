import SwiftUI

// Chess piece types
enum ChessPieceType: Equatable {
    case pawn, rook, knight, bishop, queen, king
    
    // Point values for pieces (used in AI evaluation)
    var value: Int {
        switch self {
        case .pawn: return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook: return 5
        case .queen: return 9
        case .king: return 100
        }
    }
}

// Chess piece colors
enum ChessPieceColor {
    case white, black
    
    // Get the opposite color
    var opposite: ChessPieceColor {
        return self == .white ? .black : .white
    }
}

// AI difficulty levels
enum ChessAIDifficulty {
    case none
    case easy
    case medium
    case hard
    
    // How many moves ahead the AI looks
    var searchDepth: Int {
        switch self {
        case .none: return 0
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }
}

// Chess piece representation
struct ChessPiece: Equatable {
    let type: ChessPieceType
    let color: ChessPieceColor
    var hasMoved: Bool = false
    
    var symbol: String {
        switch type {
        case .pawn:
            return color == .white ? "♙" : "♟"
        case .rook:
            return color == .white ? "♖" : "♜"
        case .knight:
            return color == .white ? "♘" : "♞"
        case .bishop:
            return color == .white ? "♗" : "♝"
        case .queen:
            return color == .white ? "♕" : "♛"
        case .king:
            return color == .white ? "♔" : "♚"
        }
    }
}

// Move representation for AI
struct ChessMove: Equatable {
    let from: (Int, Int)
    let to: (Int, Int)
    var score: Int = 0
    
    // Special move types
    var isCastling = false
    var isPromotion = false
    var promotionPiece: ChessPieceType?
    
    static func == (lhs: ChessMove, rhs: ChessMove) -> Bool {
          return lhs.from == rhs.from &&
                 lhs.to == rhs.to &&
                 lhs.score == rhs.score &&
                 lhs.isCastling == rhs.isCastling &&
                 lhs.isPromotion == rhs.isPromotion &&
                 lhs.promotionPiece == rhs.promotionPiece
      }
    
}

// Game model to handle chess logic
class ChessGameModel: ObservableObject {
    @Published var board: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    @Published var selectedSquare: (Int, Int)? = nil
    @Published var isWhiteTurn = true
    @Published var winner: ChessPieceColor? = nil
    @Published var whiteInCheck = false
    @Published var blackInCheck = false
    @Published var whiteInCheckmate = false
    @Published var blackInCheckmate = false
    @Published var validMoves: [(Int, Int)] = []
    @Published var aiDifficulty: ChessAIDifficulty = .none
    @Published var isAIThinking = false
    @Published var showGameOptionsModal = false
    @Published var gameInProgress = false
    
    // Constants for board colors
    let lightSquareColor = Color(red: 0.9, green: 0.9, blue: 0.8) // Cream
    let darkSquareColor = Color(red: 0.4, green: 0.2, blue: 0.1)  // Brown
    
    init() {
        showGameOptionsModal = true
    }
    
    // Initialize the game board with pieces
    func resetGame() {
        showGameOptionsModal = true
        gameInProgress = false
    }
    
    // Start a new game with the selected options
    func startNewGame() {
        // Clear the board
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        
        // Set up pawns
        for col in 0..<8 {
            board[1][col] = ChessPiece(type: .pawn, color: .black)
            board[6][col] = ChessPiece(type: .pawn, color: .white)
        }
        
        // Set up black pieces
        board[0][0] = ChessPiece(type: .rook, color: .black)
        board[0][1] = ChessPiece(type: .knight, color: .black)
        board[0][2] = ChessPiece(type: .bishop, color: .black)
        board[0][3] = ChessPiece(type: .queen, color: .black)
        board[0][4] = ChessPiece(type: .king, color: .black)
        board[0][5] = ChessPiece(type: .bishop, color: .black)
        board[0][6] = ChessPiece(type: .knight, color: .black)
        board[0][7] = ChessPiece(type: .rook, color: .black)
        
        // Set up white pieces
        board[7][0] = ChessPiece(type: .rook, color: .white)
        board[7][1] = ChessPiece(type: .knight, color: .white)
        board[7][2] = ChessPiece(type: .bishop, color: .white)
        board[7][3] = ChessPiece(type: .queen, color: .white)
        board[7][4] = ChessPiece(type: .king, color: .white)
        board[7][5] = ChessPiece(type: .bishop, color: .white)
        board[7][6] = ChessPiece(type: .knight, color: .white)
        board[7][7] = ChessPiece(type: .rook, color: .white)
        
        selectedSquare = nil
        isWhiteTurn = true
        winner = nil
        whiteInCheck = false
        blackInCheck = false
        whiteInCheckmate = false
        blackInCheckmate = false
        validMoves = []
        gameInProgress = true
        showGameOptionsModal = false
        
        // If AI is enabled and it's black's turn, make an AI move
        if !isWhiteTurn && aiDifficulty != .none {
            makeAIMove()
        }
    }
    
    // Set AI difficulty
    func setAIDifficulty(_ difficulty: ChessAIDifficulty) {
        self.aiDifficulty = difficulty
        // If it's already AI's turn, make a move
        if !isWhiteTurn && aiDifficulty != .none && gameInProgress {
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
        if !isWhiteTurn && aiDifficulty != .none {
            return
        }
        
        // If a square is already selected
        if let (selectedRow, selectedCol) = selectedSquare {
            // If tapping on the same square, deselect it
            if selectedRow == row && selectedCol == col {
                selectedSquare = nil
                validMoves = []
                return
            }
            
            // Try to move the selected piece
            if let piece = board[selectedRow][selectedCol], 
               (piece.color == .white && isWhiteTurn) || (piece.color == .black && !isWhiteTurn) {
                
                // Check if this is a castling move
                if piece.type == .king && !piece.hasMoved && abs(col - selectedCol) == 2 {
                    let rookCol = col > selectedCol ? 7 : 0
                    if ChessGameLogic.canCastle(for: self, kingPosition: (selectedRow, selectedCol), rookPosition: (selectedRow, rookCol)) {
                        ChessGameLogic.performCastle(for: self, kingPosition: (selectedRow, selectedCol), rookPosition: (selectedRow, rookCol))
                        selectedSquare = nil
                        validMoves = []
                        
                        // If it's now AI's turn, make an AI move
                        if !isWhiteTurn && aiDifficulty != .none && winner == nil {
                            makeAIMove()
                        }
                        return
                    }
                }
                
                if ChessGameLogic.isValidMove(for: self, from: (selectedRow, selectedCol), to: (row, col)) {
                    // Check if the move would leave the player's king in check
                    if !ChessGameLogic.moveWouldCauseCheck(for: self, from: (selectedRow, selectedCol), to: (row, col), color: piece.color) {
                        ChessGameLogic.movePiece(for: self, from: (selectedRow, selectedCol), to: (row, col))
                        selectedSquare = nil
                        validMoves = []
                        
                        // If it's now AI's turn, make an AI move
                        if !isWhiteTurn && aiDifficulty != .none && winner == nil {
                            makeAIMove()
                        }
                        return
                    }
                }
            }
        }
        
        // Select a piece if it's the player's turn
        if let piece = board[row][col] {
            if (isWhiteTurn && piece.color == .white) || (!isWhiteTurn && piece.color == .black && aiDifficulty == .none) {
                selectedSquare = (row, col)
                validMoves = ChessGameLogic.getValidMoves(for: self, at: (row, col))
            }
        }
    }
    
    // Make an AI move - delegate to ChessAI
    func makeAIMove() {
        ChessAI.makeAIMove(for: self)
    }
} 

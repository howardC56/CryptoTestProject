import SwiftUI

// AI helper for the chess game
class ChessAI {
    // Make an AI move based on the current difficulty
    static func makeAIMove(for gameModel: ChessGameModel) {
        // Simulate AI thinking
        gameModel.isAIThinking = true
        
        // Delay to simulate thinking - longer for higher difficulties
        let thinkingTime: TimeInterval
        switch gameModel.aiDifficulty {
        case .easy:
            thinkingTime = 0.5
        case .medium:
            thinkingTime = 1.0
        case .hard:
            thinkingTime = 1.5
        case .none:
            thinkingTime = 0
        }
        
        // Perform the AI move after the thinking delay
        DispatchQueue.main.asyncAfter(deadline: .now() + thinkingTime) { [weak gameModel] in
            guard let gameModel = gameModel else { return }
            
            switch gameModel.aiDifficulty {
            case .easy:
                makeEasyAIMove(for: gameModel)
            case .medium:
                makeMediumAIMove(for: gameModel)
            case .hard:
                makeHardAIMove(for: gameModel)
            case .none:
                break
            }
            
            gameModel.isAIThinking = false
        }
    }
    
    // Easy difficulty AI logic - random legal moves
    private static func makeEasyAIMove(for gameModel: ChessGameModel) {
        // Get all legal moves for black
        let moves = ChessGameLogic.getAllLegalMoves(for: gameModel, color: .black)
        
        // If no legal moves, game is over
        if moves.isEmpty {
            return
        }
        
        // Choose a random move
        if let randomMove = moves.randomElement() {
            if randomMove.isCastling {
                // Handle castling
                let kingPosition = randomMove.from
                let kingRow = kingPosition.0
                let kingCol = kingPosition.1
                let direction = randomMove.to.1 > kingCol ? 1 : -1
                let rookCol = direction > 0 ? 7 : 0
                
                ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
            } else {
                // Regular move
                ChessGameLogic.movePiece(for: gameModel, from: randomMove.from, to: randomMove.to)
            }
        }
    }
    
    // Medium difficulty AI logic - captures and checks
    private static func makeMediumAIMove(for gameModel: ChessGameModel) {
        // Get all legal moves for black
        var moves = ChessGameLogic.getAllLegalMoves(for: gameModel, color: .black)
        
        // If no legal moves, game is over
        if moves.isEmpty {
            return
        }
        
        // Score each move
        for i in 0..<moves.count {
            moves[i].score = evaluateMove(move: moves[i], for: gameModel)
        }
        
        // Sort moves by score (highest first)
        moves.sort { $0.score > $1.score }
        
        // Choose one of the top 3 moves (with some randomness)
        let topMoveCount = min(3, moves.count)
        let selectedIndex = Int.random(in: 0..<topMoveCount)
        let selectedMove = moves[selectedIndex]
        
        if selectedMove.isCastling {
            // Handle castling
            let kingPosition = selectedMove.from
            let kingRow = kingPosition.0
            let kingCol = kingPosition.1
            let direction = selectedMove.to.1 > kingCol ? 1 : -1
            let rookCol = direction > 0 ? 7 : 0
            
            ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
        } else {
            // Regular move
            ChessGameLogic.movePiece(for: gameModel, from: selectedMove.from, to: selectedMove.to)
        }
    }
    
    // Hard difficulty AI logic - minimax with alpha-beta pruning
    private static func makeHardAIMove(for gameModel: ChessGameModel) {
        let bestMove = findBestMove(for: gameModel)
        
        if let move = bestMove {
            if move.isCastling {
                // Handle castling
                let kingPosition = move.from
                let kingRow = kingPosition.0
                let kingCol = kingPosition.1
                let direction = move.to.1 > kingCol ? 1 : -1
                let rookCol = direction > 0 ? 7 : 0
                
                ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
            } else {
                // Regular move
                ChessGameLogic.movePiece(for: gameModel, from: move.from, to: move.to)
            }
        }
    }
    
    // Evaluate a single move for medium difficulty
    private static func evaluateMove(move: ChessMove, for gameModel: ChessGameModel) -> Int {
        var score = 0
        let (fromRow, fromCol) = move.from
        let (toRow, toCol) = move.to
        
        // Piece values for capture evaluation
        let pieceValues: [ChessPieceType: Int] = [
            .pawn: 10,
            .knight: 30,
            .bishop: 30,
            .rook: 50,
            .queen: 90,
            .king: 900
        ]
        
        // Check if it's a capture move
        if let capturedPiece = gameModel.board[toRow][toCol] {
            // Capturing pieces is good
            score += pieceValues[capturedPiece.type] ?? 0
        }
        
        // Simulate the move
        let originalPiece = gameModel.board[toRow][toCol]
        gameModel.board[toRow][toCol] = gameModel.board[fromRow][fromCol]
        gameModel.board[fromRow][fromCol] = nil
        
        // Check if move puts opponent in check
        if ChessGameLogic.isInCheck(for: gameModel, color: .white) {
            score += 15 // Bonus for putting opponent in check
        }
        
        // Check if move would put self in check (bad)
        if ChessGameLogic.isInCheck(for: gameModel, color: .black) {
            score -= 20 // Penalty for putting self in check
        }
        
        // Undo the move
        gameModel.board[fromRow][fromCol] = gameModel.board[toRow][toCol]
        gameModel.board[toRow][toCol] = originalPiece
        
        // Bonus for center control (central squares)
        if (toRow >= 3 && toRow <= 4) && (toCol >= 3 && toCol <= 4) {
            score += 5
        }
        
        // Bonus for pawn advancement
        if let piece = gameModel.board[fromRow][fromCol], piece.type == .pawn {
            // Black pawns want to advance toward row 7
            let advancement = toRow - fromRow
            score += advancement * 2
        }
        
        // Bonus for castling (king safety)
        if move.isCastling {
            score += 20
        }
        
        return score
    }
    
    // Find the best move using minimax with alpha-beta pruning
    private static func findBestMove(for gameModel: ChessGameModel) -> ChessMove? {
        let depth = gameModel.aiDifficulty.searchDepth
        var bestMove: ChessMove?
        var bestScore = Int.min
        
        // Get all legal moves for black
        let moves = ChessGameLogic.getAllLegalMoves(for: gameModel, color: .black)
        
        // If no legal moves, game is over
        if moves.isEmpty {
            return nil
        }
        
        // Try each move and evaluate using minimax
        for move in moves {
            // Make the move on a copy of the board
            let boardCopy = ChessGameLogic.copyBoard(gameModel.board)
            let originalPiece = gameModel.board[move.to.0][move.to.1]
            
            // Apply move
            if move.isCastling {
                let kingPosition = move.from
                let kingRow = kingPosition.0
                let kingCol = kingPosition.1
                let direction = move.to.1 > kingCol ? 1 : -1
                let rookCol = direction > 0 ? 7 : 0
                
                ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
            } else {
                gameModel.board[move.to.0][move.to.1] = gameModel.board[move.from.0][move.from.1]
                gameModel.board[move.from.0][move.from.1] = nil
                
                // Handle pawn promotion
                if let piece = gameModel.board[move.to.0][move.to.1], piece.type == .pawn && move.to.0 == 7 {
                    gameModel.board[move.to.0][move.to.1] = ChessPiece(type: .queen, color: .black, hasMoved: true)
                }
            }
            
            // Evaluate position using minimax
            let score = minimax(gameModel: gameModel, depth: depth - 1, alpha: Int.min, beta: Int.max, maximizingPlayer: false)
            
            // Restore the board
            gameModel.board = boardCopy
            
            // Update best move if needed
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    // Minimax algorithm with alpha-beta pruning
    private static func minimax(gameModel: ChessGameModel, depth: Int, alpha: Int, beta: Int, maximizingPlayer: Bool) -> Int {
        // Base case: reached depth limit or game over
        if depth == 0 || gameModel.winner != nil {
            return evaluateBoard(for: gameModel)
        }
        
        let color = maximizingPlayer ? ChessPieceColor.black : ChessPieceColor.white
        let moves = ChessGameLogic.getAllLegalMoves(for: gameModel, color: color)
        
        // No legal moves - checkmate or stalemate
        if moves.isEmpty {
            // If in check, it's checkmate
            if (maximizingPlayer && ChessGameLogic.isInCheck(for: gameModel, color: .black)) ||
               (!maximizingPlayer && ChessGameLogic.isInCheck(for: gameModel, color: .white)) {
                return maximizingPlayer ? -1000 - depth : 1000 + depth // Prefer checkmate in fewer moves
            }
            return 0 // Stalemate
        }
        
        var alpha = alpha
        var beta = beta
        
        if maximizingPlayer {
            var maxEval = Int.min
            
            for move in moves {
                // Make the move on a copy of the board
                let boardCopy = ChessGameLogic.copyBoard(gameModel.board)
                
                // Apply move
                if move.isCastling {
                    let kingPosition = move.from
                    let kingRow = kingPosition.0
                    let kingCol = kingPosition.1
                    let direction = move.to.1 > kingCol ? 1 : -1
                    let rookCol = direction > 0 ? 7 : 0
                    
                    ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
                } else {
                    gameModel.board[move.to.0][move.to.1] = gameModel.board[move.from.0][move.from.1]
                    gameModel.board[move.from.0][move.from.1] = nil
                    
                    // Handle pawn promotion
                    if let piece = gameModel.board[move.to.0][move.to.1], piece.type == .pawn && move.to.0 == 7 {
                        gameModel.board[move.to.0][move.to.1] = ChessPiece(type: .queen, color: .black, hasMoved: true)
                    }
                }
                
                let eval = minimax(gameModel: gameModel, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: false)
                maxEval = max(maxEval, eval)
                
                // Restore the board
                gameModel.board = boardCopy
                
                // Alpha-beta pruning
                alpha = max(alpha, eval)
                if beta <= alpha {
                    break
                }
            }
            
            return maxEval
        } else {
            var minEval = Int.max
            
            for move in moves {
                // Make the move on a copy of the board
                let boardCopy = ChessGameLogic.copyBoard(gameModel.board)
                
                // Apply move
                if move.isCastling {
                    let kingPosition = move.from
                    let kingRow = kingPosition.0
                    let kingCol = kingPosition.1
                    let direction = move.to.1 > kingCol ? 1 : -1
                    let rookCol = direction > 0 ? 7 : 0
                    
                    ChessGameLogic.performCastle(for: gameModel, kingPosition: kingPosition, rookPosition: (kingRow, rookCol))
                } else {
                    gameModel.board[move.to.0][move.to.1] = gameModel.board[move.from.0][move.from.1]
                    gameModel.board[move.from.0][move.from.1] = nil
                    
                    // Handle pawn promotion
                    if let piece = gameModel.board[move.to.0][move.to.1], piece.type == .pawn && move.to.0 == 0 {
                        gameModel.board[move.to.0][move.to.1] = ChessPiece(type: .queen, color: .white, hasMoved: true)
                    }
                }
                
                let eval = minimax(gameModel: gameModel, depth: depth - 1, alpha: alpha, beta: beta, maximizingPlayer: true)
                minEval = min(minEval, eval)
                
                // Restore the board
                gameModel.board = boardCopy
                
                // Alpha-beta pruning
                beta = min(beta, eval)
                if beta <= alpha {
                    break
                }
            }
            
            return minEval
        }
    }
    
    // Evaluate the board position (positive is good for black, negative is good for white)
    private static func evaluateBoard(for gameModel: ChessGameModel) -> Int {
        var score = 0
        
        // Material value
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = gameModel.board[row][col] {
                    let pieceValue = piece.type.value
                    
                    // Add value for black pieces, subtract for white
                    if piece.color == .black {
                        score += pieceValue
                    } else {
                        score -= pieceValue
                    }
                    
                    // Position-based evaluation
                    score += positionValue(piece: piece, row: row, col: col)
                }
            }
        }
        
        // Check and checkmate evaluation
        if ChessGameLogic.isInCheck(for: gameModel, color: .white) {
            score += 50 // Bonus for putting white in check
            
            if ChessGameLogic.isInCheckmate(for: gameModel, color: .white) {
                score += 10000 // Huge bonus for checkmate
            }
        }
        
        if ChessGameLogic.isInCheck(for: gameModel, color: .black) {
            score -= 50 // Penalty for being in check
            
            if ChessGameLogic.isInCheckmate(for: gameModel, color: .black) {
                score -= 10000 // Huge penalty for being checkmated
            }
        }
        
        return score
    }
    
    // Evaluate piece position
    private static func positionValue(piece: ChessPiece, row: Int, col: Int) -> Int {
        var positionScore = 0
        
        switch piece.type {
        case .pawn:
            // Pawns are more valuable as they advance
            if piece.color == .black {
                positionScore += row // Black pawns want to advance toward row 7
            } else {
                positionScore += (7 - row) // White pawns want to advance toward row 0
            }
            
            // Central pawns are more valuable
            if col >= 2 && col <= 5 {
                positionScore += 2
            }
            
        case .knight:
            // Knights are more valuable in the center
            if row >= 2 && row <= 5 && col >= 2 && col <= 5 {
                positionScore += 5
            }
            
        case .bishop:
            // Bishops control more squares when they're not on the edge
            if col > 0 && col < 7 {
                positionScore += 3
            }
            
        case .rook:
            // Rooks are valuable on open files and the 7th rank
            if piece.color == .black && row == 6 {
                positionScore += 10 // Black rook on 7th rank
            } else if piece.color == .white && row == 1 {
                positionScore += 10 // White rook on 7th rank
            }
            
        case .queen:
            // Queens are slightly better in the center but should generally stay back until endgame
            if row >= 2 && row <= 5 && col >= 2 && col <= 5 {
                positionScore += 2
            }
            
        case .king:
            // Kings should stay protected in the early/middle game
            // In the early game, encourage castling
            if piece.color == .black {
                if row <= 1 && (col <= 2 || col >= 6) { // Castled position
                    positionScore += 10
                }
            } else {
                if row >= 6 && (col <= 2 || col >= 6) { // Castled position
                    positionScore += 10
                }
            }
        }
        
        // Adjust score based on piece color
        return piece.color == .black ? positionScore : -positionScore
    }
} 
import SwiftUI

// AI helper for the checkers game
class CheckersAI {
    // Make an AI move based on the current difficulty
    static func makeAIMove(for gameModel: CheckersGameModel) {
        // Simulate AI thinking
        gameModel.isAIThinking = true
        
        // Delay to simulate thinking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak gameModel] in
            guard let gameModel = gameModel else { return }
            
            switch gameModel.aiDifficulty {
            case .medium:
                makeMediumAIMove(for: gameModel)
            case .none:
                break
            }
            
            gameModel.isAIThinking = false
            gameModel.checkForWinner()
        }
    }
    
    // Medium difficulty AI logic
    private static func makeMediumAIMove(for gameModel: CheckersGameModel) {
        // First priority: Look for jumps (captures)
        if let jumpMove = findBestJumpMove(for: gameModel) {
            gameModel.movePiece(from: jumpMove.from, to: jumpMove.to)
            return
        }
        
        // Second priority: Make a safe move
        if let safeMove = findSafeMove(for: gameModel) {
            gameModel.movePiece(from: safeMove.from, to: safeMove.to)
            return
        }
        
        // Fallback: Make any valid move
        if let anyMove = findAnyValidMove(for: gameModel) {
            gameModel.movePiece(from: anyMove.from, to: anyMove.to)
            return
        }
        
        // If no moves are available, the player wins
        gameModel.winner = .red
        gameModel.gameInProgress = false
    }
    
    // Find a move that captures a piece
    private static func findBestJumpMove(for gameModel: CheckersGameModel) -> (from: (Int, Int), to: (Int, Int))? {
        var possibleJumps = [(from: (Int, Int), to: (Int, Int))]()
        
        // Look for all possible jumps
        for row in 0..<8 {
            for col in 0..<8 {
                let piece = gameModel.board[row][col]
                if piece == .black || piece == .blackKing {
                    // Check all possible jump directions
                    for (rowOffset, colOffset) in [(2, 2), (2, -2), (-2, 2), (-2, -2)] {
                        let newRow = row + rowOffset
                        let newCol = col + colOffset
                        
                        // Check bounds
                        if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                            if CheckersGameLogic.isValidMove(for: gameModel, from: (row, col), to: (newRow, newCol)) {
                                possibleJumps.append((from: (row, col), to: (newRow, newCol)))
                            }
                        }
                    }
                }
            }
        }
        
        // Prioritize jumps that capture kings
        for jump in possibleJumps {
            let jumpedRow = (jump.from.0 + jump.to.0) / 2
            let jumpedCol = (jump.from.1 + jump.to.1) / 2
            if gameModel.board[jumpedRow][jumpedCol] == .redKing {
                return jump
            }
        }
        
        // If no king captures, return any jump
        return possibleJumps.first
    }
    
    // Find a move that doesn't put the piece in danger
    private static func findSafeMove(for gameModel: CheckersGameModel) -> (from: (Int, Int), to: (Int, Int))? {
        var possibleMoves = [(from: (Int, Int), to: (Int, Int))]()
        
        // Look for all possible regular moves
        for row in 0..<8 {
            for col in 0..<8 {
                let piece = gameModel.board[row][col]
                if piece == .black || piece == .blackKing {
                    // Check all possible move directions
                    for (rowOffset, colOffset) in [(1, 1), (1, -1), (-1, 1), (-1, -1)] {
                        let newRow = row + rowOffset
                        let newCol = col + colOffset
                        
                        // Check bounds
                        if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                            if CheckersGameLogic.isValidMove(for: gameModel, from: (row, col), to: (newRow, newCol)) {
                                // Check if this move is safe (won't be captured immediately)
                                if isSafeMove(for: gameModel, from: (row, col), to: (newRow, newCol)) {
                                    possibleMoves.append((from: (row, col), to: (newRow, newCol)))
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Prioritize moves that advance kings or create kings
        for move in possibleMoves {
            let piece = gameModel.board[move.from.0][move.from.1]
            if piece == .blackKing || move.to.0 == 7 {
                return move
            }
        }
        
        // If no priority moves, return any safe move
        return possibleMoves.first
    }
    
    // Check if a move is safe (won't be captured immediately after)
    private static func isSafeMove(for gameModel: CheckersGameModel, from: (Int, Int), to: (Int, Int)) -> Bool {
        // Create a temporary board to simulate the move
        var tempBoard = gameModel.board
        var piece = tempBoard[from.0][from.1]
        tempBoard[from.0][from.1] = .empty
        
        // Check if piece should be promoted to king
        if piece == .black && to.0 == 7 {
            piece = .blackKing
        }
        
        tempBoard[to.0][to.1] = piece
        
        // Check if any red piece can capture this piece after the move
        for row in 0..<8 {
            for col in 0..<8 {
                let checkPiece = tempBoard[row][col]
                if checkPiece == .red || checkPiece == .redKing {
                    // Check if this red piece can jump over our moved piece
                    for (rowOffset, colOffset) in [(2, 2), (2, -2), (-2, 2), (-2, -2)] {
                        let jumpRow = row + rowOffset
                        let jumpCol = col + colOffset
                        
                        // Check bounds
                        if jumpRow >= 0 && jumpRow < 8 && jumpCol >= 0 && jumpCol < 8 {
                            // Check if the jump would capture our piece
                            let midRow = (row + jumpRow) / 2
                            let midCol = (col + jumpCol) / 2
                            
                            if midRow == to.0 && midCol == to.1 && tempBoard[jumpRow][jumpCol] == .empty {
                                // This move would allow our piece to be captured
                                return false
                            }
                        }
                    }
                }
            }
        }
        
        return true
    }
    
    // Find any valid move
    private static func findAnyValidMove(for gameModel: CheckersGameModel) -> (from: (Int, Int), to: (Int, Int))? {
        for row in 0..<8 {
            for col in 0..<8 {
                let piece = gameModel.board[row][col]
                if piece == .black || piece == .blackKing {
                    // Check all possible move directions
                    for (rowOffset, colOffset) in [(1, 1), (1, -1), (-1, 1), (-1, -1)] {
                        let newRow = row + rowOffset
                        let newCol = col + colOffset
                        
                        // Check bounds
                        if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                            if CheckersGameLogic.isValidMove(for: gameModel, from: (row, col), to: (newRow, newCol)) {
                                return (from: (row, col), to: (newRow, newCol))
                            }
                        }
                    }
                }
            }
        }
        
        return nil
    }
} 
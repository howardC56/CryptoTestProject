import SwiftUI

// Game logic helper for the checkers game
class CheckersGameLogic {
    // Check if a move is valid
    static func isValidMove(for gameModel: CheckersGameModel, from: (Int, Int), to: (Int, Int)) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Must move to an empty square
        if gameModel.board[toRow][toCol] != .empty {
            return false
        }
        
        // Must move diagonally
        if abs(toRow - fromRow) != abs(toCol - fromCol) {
            return false
        }
        
        let piece = gameModel.board[fromRow][fromCol]
        
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
            let jumpedPiece = gameModel.board[jumpedRow][jumpedCol]
            
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
    static func movePiece(for gameModel: CheckersGameModel, from: (Int, Int), to: (Int, Int)) {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Move the piece
        var piece = gameModel.board[fromRow][fromCol]
        gameModel.board[fromRow][fromCol] = .empty
        
        // Check if piece should be promoted to king
        if piece == .red && toRow == 0 {
            piece = .redKing
        } else if piece == .black && toRow == 7 {
            piece = .blackKing
        }
        
        gameModel.board[toRow][toCol] = piece
        
        // If it was a jump, remove the jumped piece
        if abs(toRow - fromRow) == 2 {
            let jumpedRow = (fromRow + toRow) / 2
            let jumpedCol = (fromCol + toCol) / 2
            
            let jumpedPiece = gameModel.board[jumpedRow][jumpedCol]
            if jumpedPiece == .red || jumpedPiece == .redKing {
                gameModel.redPiecesCount -= 1
            } else if jumpedPiece == .black || jumpedPiece == .blackKing {
                gameModel.blackPiecesCount -= 1
            }
            
            gameModel.board[jumpedRow][jumpedCol] = .empty
        }
        
        // Switch turns
        gameModel.isRedTurn.toggle()
    }
    
    // Check for a winner
    static func checkForWinner(for gameModel: CheckersGameModel) {
        if gameModel.redPiecesCount == 0 {
            gameModel.winner = .black
            gameModel.gameInProgress = false
        } else if gameModel.blackPiecesCount == 0 {
            gameModel.winner = .red
            gameModel.gameInProgress = false
        }
    }
} 
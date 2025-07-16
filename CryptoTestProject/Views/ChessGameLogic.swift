import SwiftUI

// Game logic helper for the chess game
class ChessGameLogic {
    // Find the position of a king
    static func findKing(for gameModel: ChessGameModel, color: ChessPieceColor) -> (Int, Int)? {
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = gameModel.board[row][col], 
                   piece.type == .king && piece.color == color {
                    return (row, col)
                }
            }
        }
        return nil
    }
    
    // Check if a king is in check
    static func isInCheck(for gameModel: ChessGameModel, color: ChessPieceColor) -> Bool {
        guard let kingPosition = findKing(for: gameModel, color: color) else { return false }
        
        // Check if any opponent piece can capture the king
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = gameModel.board[row][col], piece.color != color {
                    if isValidMove(for: gameModel, from: (row, col), to: kingPosition, checkForCheck: false) {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // Check if a move would leave the player's king in check
    static func moveWouldCauseCheck(for gameModel: ChessGameModel, from: (Int, Int), to: (Int, Int), color: ChessPieceColor) -> Bool {
        // Make a temporary move
        let tempPiece = gameModel.board[to.0][to.1]
        gameModel.board[to.0][to.1] = gameModel.board[from.0][from.1]
        gameModel.board[from.0][from.1] = nil
        
        // Check if the king is in check after the move
        let inCheck = isInCheck(for: gameModel, color: color)
        
        // Undo the move
        gameModel.board[from.0][from.1] = gameModel.board[to.0][to.1]
        gameModel.board[to.0][to.1] = tempPiece
        
        return inCheck
    }
    
    // Check if a player is in checkmate
    static func isInCheckmate(for gameModel: ChessGameModel, color: ChessPieceColor) -> Bool {
        // First, check if the king is in check
        if !isInCheck(for: gameModel, color: color) {
            return false
        }
        
        // Try all possible moves for all pieces of this color
        for fromRow in 0..<8 {
            for fromCol in 0..<8 {
                if let piece = gameModel.board[fromRow][fromCol], piece.color == color {
                    // Try moving this piece to every square
                    for toRow in 0..<8 {
                        for toCol in 0..<8 {
                            // Check if this is a valid move
                            if isValidMove(for: gameModel, from: (fromRow, fromCol), to: (toRow, toCol)) {
                                // Check if this move would get the king out of check
                                if !moveWouldCauseCheck(for: gameModel, from: (fromRow, fromCol), to: (toRow, toCol), color: color) {
                                    // Found a legal move that gets out of check
                                    return false
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // No legal moves found to get out of check
        return true
    }
    
    // Update check and checkmate status
    static func updateCheckStatus(for gameModel: ChessGameModel) {
        gameModel.whiteInCheck = isInCheck(for: gameModel, color: .white)
        gameModel.blackInCheck = isInCheck(for: gameModel, color: .black)
        
        // Only check for checkmate if a player is in check
        if gameModel.whiteInCheck {
            gameModel.whiteInCheckmate = isInCheckmate(for: gameModel, color: .white)
            if gameModel.whiteInCheckmate {
                gameModel.winner = .black
            }
        } else {
            gameModel.whiteInCheckmate = false
        }
        
        if gameModel.blackInCheck {
            gameModel.blackInCheckmate = isInCheckmate(for: gameModel, color: .black)
            if gameModel.blackInCheckmate {
                gameModel.winner = .white
            }
        } else {
            gameModel.blackInCheckmate = false
        }
    }
    
    // Check if castling is valid
    static func canCastle(for gameModel: ChessGameModel, kingPosition: (Int, Int), rookPosition: (Int, Int)) -> Bool {
        let (kingRow, kingCol) = kingPosition
        let (rookRow, rookCol) = rookPosition
        
        // Make sure king and rook are in the same row
        if kingRow != rookRow {
            return false
        }
        
        // Get the king and rook pieces
        guard let king = gameModel.board[kingRow][kingCol],
              let rook = gameModel.board[rookRow][rookCol],
              king.type == .king,
              rook.type == .rook,
              king.color == rook.color,
              !king.hasMoved,
              !rook.hasMoved else {
            return false
        }
        
        // Check if the king is in check
        if isInCheck(for: gameModel, color: king.color) {
            return false
        }
        
        // Determine the direction of castling
        let direction = rookCol > kingCol ? 1 : -1
        
        // Check if there are no pieces between king and rook
        var col = kingCol + direction
        while col != rookCol {
            if gameModel.board[kingRow][col] != nil {
                return false
            }
            col += direction
        }
        
        // Check if the king would pass through or end up in check
        let kingColor = king.color
        
        // Check if the square the king moves through is under attack
        let midSquare = (kingRow, kingCol + direction)
        if moveWouldCauseCheck(for: gameModel, from: (kingRow, kingCol), to: midSquare, color: kingColor) {
            return false
        }
        
        // Check if the final square for the king would be under attack
        let finalKingSquare = (kingRow, kingCol + 2 * direction)
        if moveWouldCauseCheck(for: gameModel, from: (kingRow, kingCol), to: finalKingSquare, color: kingColor) {
            return false
        }
        
        return true
    }
    
    // Perform castling
    static func performCastle(for gameModel: ChessGameModel, kingPosition: (Int, Int), rookPosition: (Int, Int)) {
        let (kingRow, kingCol) = kingPosition
        let (rookRow, rookCol) = rookPosition
        
        // Determine the direction of castling
        let direction = rookCol > kingCol ? 1 : -1
        
        // Move the king
        let newKingCol = kingCol + 2 * direction
        gameModel.board[kingRow][newKingCol] = gameModel.board[kingRow][kingCol]
        gameModel.board[kingRow][kingCol] = nil
        
        // Update the king's hasMoved status
        gameModel.board[kingRow][newKingCol]?.hasMoved = true
        
        // Move the rook
        let newRookCol = kingCol + direction
        gameModel.board[rookRow][newRookCol] = gameModel.board[rookRow][rookCol]
        gameModel.board[rookRow][rookCol] = nil
        
        // Update the rook's hasMoved status
        gameModel.board[rookRow][newRookCol]?.hasMoved = true
        
        // Switch turns
        gameModel.isWhiteTurn.toggle()
        
        // Update check status
        updateCheckStatus(for: gameModel)
    }
    
    // Get all valid moves for a piece
    static func getValidMoves(for gameModel: ChessGameModel, at position: (Int, Int)) -> [(Int, Int)] {
        let (row, col) = position
        guard let piece = gameModel.board[row][col] else { return [] }
        
        var moves: [(Int, Int)] = []
        
        // Check all possible destination squares
        for toRow in 0..<8 {
            for toCol in 0..<8 {
                if isValidMove(for: gameModel, from: (row, col), to: (toRow, toCol)) {
                    // Check if the move would leave the king in check
                    if !moveWouldCauseCheck(for: gameModel, from: (row, col), to: (toRow, toCol), color: piece.color) {
                        moves.append((toRow, toCol))
                    }
                }
            }
        }
        
        // Check for castling if the piece is a king
        if piece.type == .king && !piece.hasMoved {
            let kingRow = row
            
            // Check kingside castling (with rook on the right)
            if col + 3 < 8, let rook = gameModel.board[kingRow][7], rook.type == .rook && !rook.hasMoved {
                if canCastle(for: gameModel, kingPosition: (kingRow, col), rookPosition: (kingRow, 7)) {
                    moves.append((kingRow, col + 2))
                }
            }
            
            // Check queenside castling (with rook on the left)
            if col - 4 >= 0, let rook = gameModel.board[kingRow][0], rook.type == .rook && !rook.hasMoved {
                if canCastle(for: gameModel, kingPosition: (kingRow, col), rookPosition: (kingRow, 0)) {
                    moves.append((kingRow, col - 2))
                }
            }
        }
        
        return moves
    }
    
    // Check if a move is valid (simplified chess rules)
    static func isValidMove(for gameModel: ChessGameModel, from: (Int, Int), to: (Int, Int), checkForCheck: Bool = true) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Must move to an empty square or capture opponent's piece
        if let targetPiece = gameModel.board[toRow][toCol] {
            if let sourcePiece = gameModel.board[fromRow][fromCol], targetPiece.color == sourcePiece.color {
                return false
            }
        }
        
        guard let piece = gameModel.board[fromRow][fromCol] else { return false }
        
        // Simplified movement rules for each piece type
        switch piece.type {
        case .pawn:
            // Pawns move forward one square (or two from starting position)
            let direction = piece.color == .white ? -1 : 1
            let startingRow = piece.color == .white ? 6 : 1
            
            // Moving forward
            if fromCol == toCol && gameModel.board[toRow][toCol] == nil {
                // One square forward
                if toRow == fromRow + direction {
                    return true
                }
                // Two squares forward from starting position
                if fromRow == startingRow && toRow == fromRow + 2 * direction && gameModel.board[fromRow + direction][fromCol] == nil {
                    return true
                }
            }
            // Capturing diagonally
            else if abs(fromCol - toCol) == 1 && toRow == fromRow + direction {
                if let targetPiece = gameModel.board[toRow][toCol], targetPiece.color != piece.color {
                    return true
                }
            }
            
        case .rook:
            // Rooks move horizontally or vertically
            if fromRow == toRow || fromCol == toCol {
                return !hasObstaclesBetween(for: gameModel, from: from, to: to)
            }
            
        case .knight:
            // Knights move in L-shape
            return (abs(fromRow - toRow) == 2 && abs(fromCol - toCol) == 1) ||
                   (abs(fromRow - toRow) == 1 && abs(fromCol - toCol) == 2)
            
        case .bishop:
            // Bishops move diagonally
            if abs(fromRow - toRow) == abs(fromCol - toCol) {
                return !hasObstaclesBetween(for: gameModel, from: from, to: to)
            }
            
        case .queen:
            // Queens move horizontally, vertically, or diagonally
            if fromRow == toRow || fromCol == toCol || abs(fromRow - toRow) == abs(fromCol - toCol) {
                return !hasObstaclesBetween(for: gameModel, from: from, to: to)
            }
            
        case .king:
            // Kings move one square in any direction
            return abs(fromRow - toRow) <= 1 && abs(fromCol - toCol) <= 1
        }
        
        return false
    }
    
    // Check if there are any pieces between the source and destination
    static func hasObstaclesBetween(for gameModel: ChessGameModel, from: (Int, Int), to: (Int, Int)) -> Bool {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        let rowStep = fromRow == toRow ? 0 : (toRow > fromRow ? 1 : -1)
        let colStep = fromCol == toCol ? 0 : (toCol > fromCol ? 1 : -1)
        
        var row = fromRow + rowStep
        var col = fromCol + colStep
        
        while row != toRow || col != toCol {
            if gameModel.board[row][col] != nil {
                return true
            }
            row += rowStep
            col += colStep
        }
        
        return false
    }
    
    // Move a piece on the board
    static func movePiece(for gameModel: ChessGameModel, from: (Int, Int), to: (Int, Int)) {
        let (fromRow, fromCol) = from
        let (toRow, toCol) = to
        
        // Check if it's a king capture (win condition)
        if let targetPiece = gameModel.board[toRow][toCol], targetPiece.type == .king {
            gameModel.winner = gameModel.isWhiteTurn ? .white : .black
        }
        
        // Handle pawn promotion (to queen by default)
        var movingPiece = gameModel.board[fromRow][fromCol]!
        if movingPiece.type == .pawn {
            // Pawn reaches the opposite end of the board
            if (movingPiece.color == .white && toRow == 0) || (movingPiece.color == .black && toRow == 7) {
                movingPiece = ChessPiece(type: .queen, color: movingPiece.color, hasMoved: true)
            }
        }
        
        // Move the piece
        gameModel.board[toRow][toCol] = movingPiece
        gameModel.board[fromRow][fromCol] = nil
        
        // Update the piece's hasMoved status
        gameModel.board[toRow][toCol]?.hasMoved = true
        
        // Switch turns
        gameModel.isWhiteTurn.toggle()
        
        // Update check and checkmate status after move
        updateCheckStatus(for: gameModel)
    }
    
    // Get all legal moves for a specific color
    static func getAllLegalMoves(for gameModel: ChessGameModel, color: ChessPieceColor) -> [ChessMove] {
        var moves: [ChessMove] = []
        
        for fromRow in 0..<8 {
            for fromCol in 0..<8 {
                if let piece = gameModel.board[fromRow][fromCol], piece.color == color {
                    for toRow in 0..<8 {
                        for toCol in 0..<8 {
                            if isValidMove(for: gameModel, from: (fromRow, fromCol), to: (toRow, toCol)) {
                                // Check if the move would leave the king in check
                                if !moveWouldCauseCheck(for: gameModel, from: (fromRow, fromCol), to: (toRow, toCol), color: color) {
                                    let move = ChessMove(from: (fromRow, fromCol), to: (toRow, toCol))
                                    moves.append(move)
                                }
                            }
                        }
                    }
                    
                    // Check for castling if the piece is a king
                    if piece.type == .king && !piece.hasMoved {
                        let kingRow = fromRow
                        
                        // Check kingside castling (with rook on the right)
                        if fromCol + 3 < 8, let rook = gameModel.board[kingRow][7], rook.type == .rook && !rook.hasMoved {
                            if canCastle(for: gameModel, kingPosition: (kingRow, fromCol), rookPosition: (kingRow, 7)) {
                                var move = ChessMove(from: (kingRow, fromCol), to: (kingRow, fromCol + 2))
                                move.isCastling = true
                                moves.append(move)
                            }
                        }
                        
                        // Check queenside castling (with rook on the left)
                        if fromCol - 4 >= 0, let rook = gameModel.board[kingRow][0], rook.type == .rook && !rook.hasMoved {
                            if canCastle(for: gameModel, kingPosition: (kingRow, fromCol), rookPosition: (kingRow, 0)) {
                                var move = ChessMove(from: (kingRow, fromCol), to: (kingRow, fromCol - 2))
                                move.isCastling = true
                                moves.append(move)
                            }
                        }
                    }
                }
            }
        }
        
        return moves
    }
    
    // Make a copy of the board for AI evaluation
    static func copyBoard(_ board: [[ChessPiece?]]) -> [[ChessPiece?]] {
        var newBoard = Array(repeating: Array(repeating: nil as ChessPiece?, count: 8), count: 8)
        
        for row in 0..<8 {
            for col in 0..<8 {
                newBoard[row][col] = board[row][col]
            }
        }
        
        return newBoard
    }
} 
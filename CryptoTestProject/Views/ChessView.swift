import SwiftUI

// Chess piece types
//enum ChessPieceType {
//    case pawn, rook, knight, bishop, queen, king
//}

// Chess piece colors
//enum ChessPieceColor {
//    case white, black
//}

// Chess piece representation
//struct ChessPiece: Equatable {
//    let type: ChessPieceType
//    let color: ChessPieceColor
//    var hasMoved: Bool = false
//    
//    var symbol: String {
//        switch type {
//        case .pawn:
//            return color == .white ? "♙" : "♟"
//        case .rook:
//            return color == .white ? "♖" : "♜"
//        case .knight:
//            return color == .white ? "♘" : "♞"
//        case .bishop:
//            return color == .white ? "♗" : "♝"
//        case .queen:
//            return color == .white ? "♕" : "♛"
//        case .king:
//            return color == .white ? "♔" : "♚"
//        }
//    }
//}

// Game model to handle chess logic
//class ChessGameModel: ObservableObject {
//    @Published var board: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
//    @Published var selectedSquare: (Int, Int)? = nil
//    @Published var isWhiteTurn = true
//    @Published var winner: ChessPieceColor? = nil
//    @Published var whiteInCheck = false
//    @Published var blackInCheck = false
//    @Published var whiteInCheckmate = false
//    @Published var blackInCheckmate = false
//    @Published var validMoves: [(Int, Int)] = []
//    @Published var isAIThinking: Bool = false
//    @Published var gameInProgress: Bool = false
//    @Published var aiDifficulty: ChessAIDifficulty = .none
//    @Published var showGameOptionsModal: Bool = false
//    
//    // Constants for board colors
//    let lightSquareColor = Color(red: 0.9, green: 0.9, blue: 0.8) // Cream
//    let darkSquareColor = Color(red: 0.4, green: 0.2, blue: 0.1)  // Brown
//    
//    init() {
//        resetGame()
//    }
//    
//    // Initialize the game board with pieces
//    func resetGame() {
//        // Clear the board
//        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
//        
//        // Set up pawns
//        for col in 0..<8 {
//            board[1][col] = ChessPiece(type: .pawn, color: .black)
//            board[6][col] = ChessPiece(type: .pawn, color: .white)
//        }
//        
//        // Set up black pieces
//        board[0][0] = ChessPiece(type: .rook, color: .black)
//        board[0][1] = ChessPiece(type: .knight, color: .black)
//        board[0][2] = ChessPiece(type: .bishop, color: .black)
//        board[0][3] = ChessPiece(type: .queen, color: .black)
//        board[0][4] = ChessPiece(type: .king, color: .black)
//        board[0][5] = ChessPiece(type: .bishop, color: .black)
//        board[0][6] = ChessPiece(type: .knight, color: .black)
//        board[0][7] = ChessPiece(type: .rook, color: .black)
//        
//        // Set up white pieces
//        board[7][0] = ChessPiece(type: .rook, color: .white)
//        board[7][1] = ChessPiece(type: .knight, color: .white)
//        board[7][2] = ChessPiece(type: .bishop, color: .white)
//        board[7][3] = ChessPiece(type: .queen, color: .white)
//        board[7][4] = ChessPiece(type: .king, color: .white)
//        board[7][5] = ChessPiece(type: .bishop, color: .white)
//        board[7][6] = ChessPiece(type: .knight, color: .white)
//        board[7][7] = ChessPiece(type: .rook, color: .white)
//        
//        selectedSquare = nil
//        isWhiteTurn = true
//        winner = nil
//        whiteInCheck = false
//        blackInCheck = false
//        whiteInCheckmate = false
//        blackInCheckmate = false
//        validMoves = []
//        isAIThinking = false
//        gameInProgress = false
//        aiDifficulty = .none
//        showGameOptionsModal = false
//    }
//    
//    // Find the position of a king
//    func findKing(color: ChessPieceColor) -> (Int, Int)? {
//        for row in 0..<8 {
//            for col in 0..<8 {
//                if let piece = board[row][col], 
//                   piece.type == .king && piece.color == color {
//                    return (row, col)
//                }
//            }
//        }
//        return nil
//    }
//    
//    // Check if a king is in check
//    func isInCheck(color: ChessPieceColor) -> Bool {
//        guard let kingPosition = findKing(color: color) else { return false }
//        
//        // Check if any opponent piece can capture the king
//        for row in 0..<8 {
//            for col in 0..<8 {
//                if let piece = board[row][col], piece.color != color {
//                    if isValidMove(from: (row, col), to: kingPosition, checkForCheck: false) {
//                        return true
//                    }
//                }
//            }
//        }
//        
//        return false
//    }
//    
//    // Check if a move would leave the player's king in check
//    func moveWouldCauseCheck(from: (Int, Int), to: (Int, Int), color: ChessPieceColor) -> Bool {
//        // Make a temporary move
//        let tempPiece = board[to.0][to.1]
//        board[to.0][to.1] = board[from.0][from.1]
//        board[from.0][from.1] = nil
//        
//        // Check if the king is in check after the move
//        let inCheck = isInCheck(color: color)
//        
//        // Undo the move
//        board[from.0][from.1] = board[to.0][to.1]
//        board[to.0][to.1] = tempPiece
//        
//        return inCheck
//    }
//    
//    // Check if a player is in checkmate
//    func isInCheckmate(color: ChessPieceColor) -> Bool {
//        // First, check if the king is in check
//        if !isInCheck(color: color) {
//            return false
//        }
//        
//        // Try all possible moves for all pieces of this color
//        for fromRow in 0..<8 {
//            for fromCol in 0..<8 {
//                if let piece = board[fromRow][fromCol], piece.color == color {
//                    // Try moving this piece to every square
//                    for toRow in 0..<8 {
//                        for toCol in 0..<8 {
//                            // Check if this is a valid move
//                            if isValidMove(from: (fromRow, fromCol), to: (toRow, toCol)) {
//                                // Check if this move would get the king out of check
//                                if !moveWouldCauseCheck(from: (fromRow, fromCol), to: (toRow, toCol), color: color) {
//                                    // Found a legal move that gets out of check
//                                    return false
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        
//        // No legal moves found to get out of check
//        return true
//    }
//    
//    // Update check and checkmate status
//    func updateCheckStatus() {
//        whiteInCheck = isInCheck(color: .white)
//        blackInCheck = isInCheck(color: .black)
//        
//        // Only check for checkmate if a player is in check
//        if whiteInCheck {
//            whiteInCheckmate = isInCheckmate(color: .white)
//            if whiteInCheckmate {
//                winner = .black
//            }
//        } else {
//            whiteInCheckmate = false
//        }
//        
//        if blackInCheck {
//            blackInCheckmate = isInCheckmate(color: .black)
//            if blackInCheckmate {
//                winner = .white
//            }
//        } else {
//            blackInCheckmate = false
//        }
//    }
//    
//    // Check if castling is valid
//    func canCastle(kingPosition: (Int, Int), rookPosition: (Int, Int)) -> Bool {
//        let (kingRow, kingCol) = kingPosition
//        let (rookRow, rookCol) = rookPosition
//        
//        // Make sure king and rook are in the same row
//        if kingRow != rookRow {
//            return false
//        }
//        
//        // Get the king and rook pieces
//        guard let king = board[kingRow][kingCol],
//              let rook = board[rookRow][rookCol],
//              king.type == .king,
//              rook.type == .rook,
//              king.color == rook.color,
//              !king.hasMoved,
//              !rook.hasMoved else {
//            return false
//        }
//        
//        // Check if the king is in check
//        if isInCheck(color: king.color) {
//            return false
//        }
//        
//        // Determine the direction of castling
//        let direction = rookCol > kingCol ? 1 : -1
//        
//        // Check if there are no pieces between king and rook
//        var col = kingCol + direction
//        while col != rookCol {
//            if board[kingRow][col] != nil {
//                return false
//            }
//            col += direction
//        }
//        
//        // Check if the king would pass through or end up in check
//        let kingColor = king.color
//        
//        // Check if the square the king moves through is under attack
//        let midSquare = (kingRow, kingCol + direction)
//        if moveWouldCauseCheck(from: (kingRow, kingCol), to: midSquare, color: kingColor) {
//            return false
//        }
//        
//        // Check if the final square for the king would be under attack
//        let finalKingSquare = (kingRow, kingCol + 2 * direction)
//        if moveWouldCauseCheck(from: (kingRow, kingCol), to: finalKingSquare, color: kingColor) {
//            return false
//        }
//        
//        return true
//    }
//    
//    // Perform castling
//    func performCastle(kingPosition: (Int, Int), rookPosition: (Int, Int)) {
//        let (kingRow, kingCol) = kingPosition
//        let (rookRow, rookCol) = rookPosition
//        
//        // Determine the direction of castling
//        let direction = rookCol > kingCol ? 1 : -1
//        
//        // Move the king
//        let newKingCol = kingCol + 2 * direction
//        board[kingRow][newKingCol] = board[kingRow][kingCol]
//        board[kingRow][kingCol] = nil
//        
//        // Update the king's hasMoved status
//        board[kingRow][newKingCol]?.hasMoved = true
//        
//        // Move the rook
//        let newRookCol = kingCol + direction
//        board[rookRow][newRookCol] = board[rookRow][rookCol]
//        board[rookRow][rookCol] = nil
//        
//        // Update the rook's hasMoved status
//        board[rookRow][newRookCol]?.hasMoved = true
//        
//        // Switch turns
//        isWhiteTurn.toggle()
//        
//        // Update check status
//        updateCheckStatus()
//    }
//    
//    // Get all valid moves for the selected piece
//    func getValidMoves(for position: (Int, Int)) -> [(Int, Int)] {
//        let (row, col) = position
//        guard let piece = board[row][col] else { return [] }
//        
//        var moves: [(Int, Int)] = []
//        
//        // Check all possible destination squares
//        for toRow in 0..<8 {
//            for toCol in 0..<8 {
//                if isValidMove(from: (row, col), to: (toRow, toCol)) {
//                    // Check if the move would leave the king in check
//                    if !moveWouldCauseCheck(from: (row, col), to: (toRow, toCol), color: piece.color) {
//                        moves.append((toRow, toCol))
//                    }
//                }
//            }
//        }
//        
//        // Check for castling if the piece is a king
//        if piece.type == .king && !piece.hasMoved {
//            let kingRow = row
//            
//            // Check kingside castling (with rook on the right)
//            if col + 3 < 8, let rook = board[kingRow][7], rook.type == .rook && !rook.hasMoved {
//                if canCastle(kingPosition: (kingRow, col), rookPosition: (kingRow, 7)) {
//                    moves.append((kingRow, col + 2))
//                }
//            }
//            
//            // Check queenside castling (with rook on the left)
//            if col - 4 >= 0, let rook = board[kingRow][0], rook.type == .rook && !rook.hasMoved {
//                if canCastle(kingPosition: (kingRow, col), rookPosition: (kingRow, 0)) {
//                    moves.append((kingRow, col - 2))
//                }
//            }
//        }
//        
//        return moves
//    }
//    
//    // Handle tapping on a square
//    func handleTap(row: Int, col: Int) {
//        // If there's already a winner, don't allow moves
//        if winner != nil {
//            return
//        }
//        
//        // If a square is already selected
//        if let (selectedRow, selectedCol) = selectedSquare {
//            // If tapping on the same square, deselect it
//            if selectedRow == row && selectedCol == col {
//                selectedSquare = nil
//                validMoves = []
//                return
//            }
//            
//            // Try to move the selected piece
//            if let piece = board[selectedRow][selectedCol], 
//               (piece.color == .white && isWhiteTurn) || (piece.color == .black && !isWhiteTurn) {
//                
//                // Check if this is a castling move
//                if piece.type == .king && !piece.hasMoved && abs(col - selectedCol) == 2 {
//                    let rookCol = col > selectedCol ? 7 : 0
//                    if canCastle(kingPosition: (selectedRow, selectedCol), rookPosition: (selectedRow, rookCol)) {
//                        performCastle(kingPosition: (selectedRow, selectedCol), rookPosition: (selectedRow, rookCol))
//                        selectedSquare = nil
//                        validMoves = []
//                        return
//                    }
//                }
//                
//                if isValidMove(from: (selectedRow, selectedCol), to: (row, col)) {
//                    // Check if the move would leave the player's king in check
//                    if !moveWouldCauseCheck(from: (selectedRow, selectedCol), to: (row, col), color: piece.color) {
//                        movePiece(from: (selectedRow, selectedCol), to: (row, col))
//                        selectedSquare = nil
//                        validMoves = []
//                        return
//                    } else {
//                        // Move would leave king in check - don't allow it
//                        return
//                    }
//                }
//            }
//        }
//        
//        // Select a piece if it's the player's turn
//        if let piece = board[row][col] {
//            if (isWhiteTurn && piece.color == .white) || (!isWhiteTurn && piece.color == .black) {
//                selectedSquare = (row, col)
//                validMoves = getValidMoves(for: (row, col))
//            }
//        }
//    }
//    
//    // Check if a move is valid (simplified chess rules)
//    func isValidMove(from: (Int, Int), to: (Int, Int), checkForCheck: Bool = true) -> Bool {
//        let (fromRow, fromCol) = from
//        let (toRow, toCol) = to
//        
//        // Must move to an empty square or capture opponent's piece
//        if let targetPiece = board[toRow][toCol] {
//            if let sourcePiece = board[fromRow][fromCol], targetPiece.color == sourcePiece.color {
//                return false
//            }
//        }
//        
//        guard let piece = board[fromRow][fromCol] else { return false }
//        
//        // Simplified movement rules for each piece type
//        switch piece.type {
//        case .pawn:
//            // Pawns move forward one square (or two from starting position)
//            let direction = piece.color == .white ? -1 : 1
//            let startingRow = piece.color == .white ? 6 : 1
//            
//            // Moving forward
//            if fromCol == toCol && board[toRow][toCol] == nil {
//                // One square forward
//                if toRow == fromRow + direction {
//                    return true
//                }
//                // Two squares forward from starting position
//                if fromRow == startingRow && toRow == fromRow + 2 * direction && board[fromRow + direction][fromCol] == nil {
//                    return true
//                }
//            }
//            // Capturing diagonally
//            else if abs(fromCol - toCol) == 1 && toRow == fromRow + direction {
//                if let targetPiece = board[toRow][toCol], targetPiece.color != piece.color {
//                    return true
//                }
//            }
//            
//        case .rook:
//            // Rooks move horizontally or vertically
//            if fromRow == toRow || fromCol == toCol {
//                return !hasObstaclesBetween(from: from, to: to)
//            }
//            
//        case .knight:
//            // Knights move in L-shape
//            return (abs(fromRow - toRow) == 2 && abs(fromCol - toCol) == 1) ||
//                   (abs(fromRow - toRow) == 1 && abs(fromCol - toCol) == 2)
//            
//        case .bishop:
//            // Bishops move diagonally
//            if abs(fromRow - toRow) == abs(fromCol - toCol) {
//                return !hasObstaclesBetween(from: from, to: to)
//            }
//            
//        case .queen:
//            // Queens move horizontally, vertically, or diagonally
//            if fromRow == toRow || fromCol == toCol || abs(fromRow - toRow) == abs(fromCol - toCol) {
//                return !hasObstaclesBetween(from: from, to: to)
//            }
//            
//        case .king:
//            // Kings move one square in any direction
//            return abs(fromRow - toRow) <= 1 && abs(fromCol - toCol) <= 1
//        }
//        
//        return false
//    }
//    
//    // Check if there are any pieces between the source and destination
//    func hasObstaclesBetween(from: (Int, Int), to: (Int, Int)) -> Bool {
//        let (fromRow, fromCol) = from
//        let (toRow, toCol) = to
//        
//        let rowStep = fromRow == toRow ? 0 : (toRow > fromRow ? 1 : -1)
//        let colStep = fromCol == toCol ? 0 : (toCol > fromCol ? 1 : -1)
//        
//        var row = fromRow + rowStep
//        var col = fromCol + colStep
//        
//        while row != toRow || col != toCol {
//            if board[row][col] != nil {
//                return true
//            }
//            row += rowStep
//            col += colStep
//        }
//        
//        return false
//    }
//    
//    // Move a piece on the board
//    func movePiece(from: (Int, Int), to: (Int, Int)) {
//        let (fromRow, fromCol) = from
//        let (toRow, toCol) = to
//        
//        // Check if it's a king capture (win condition)
//        if let targetPiece = board[toRow][toCol], targetPiece.type == .king {
//            winner = isWhiteTurn ? .white : .black
//        }
//        
//        // Move the piece
//        board[toRow][toCol] = board[fromRow][fromCol]
//        board[fromRow][fromCol] = nil
//        
//        // Update the piece's hasMoved status
//        board[toRow][toCol]?.hasMoved = true
//        
//        // Switch turns
//        isWhiteTurn.toggle()
//        
//        // Update check and checkmate status after move
//        updateCheckStatus()
//    }
//
//    // Set AI difficulty
//    func setAIDifficulty(_ difficulty: ChessAIDifficulty) {
//        aiDifficulty = difficulty
//    }
//
//    // Start a new game with AI
//    func startNewGame() {
//        resetGame()
//        gameInProgress = true
//        isAIThinking = true
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulate AI thinking
//            self.isAIThinking = false
//            self.updateCheckStatus() // AI move might put player in check
//        }
//    }
//}

// Single square view component
struct ChessSquareView: View {
    let row: Int
    let col: Int
    let piece: ChessPiece?
    let isSelected: Bool
    let isValidMove: Bool
    let lightColor: Color
    let darkColor: Color
    
    var body: some View {
        ZStack {
            // Square background
            Rectangle()
                .fill((row + col) % 2 == 0 ? lightColor : darkColor)
            
            // Valid move indicator
            if isValidMove {
                Circle()
                    .fill(Color.green.opacity(0.4))
                    .padding(12)
            }
            
            // Chess piece
            if let piece = piece {
                if piece.color == .white {
                    // White piece with enhanced visibility
                    Text(piece.symbol)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 1, x: 0, y: 0)
                        .shadow(color: .black, radius: 0.5, x: 0, y: 0) // Double shadow for stronger effect
                } else {
                    // Black piece (no special treatment needed)
                    Text(piece.symbol)
                        .font(.system(size: 34))
                        .foregroundColor(.black)
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
struct ChessBoardView: View {
    @ObservedObject var gameModel: ChessGameModel
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        ChessSquareView(
                            row: row,
                            col: col,
                            piece: gameModel.board[row][col],
                            isSelected: gameModel.selectedSquare.map { $0 == (row, col) } ?? false,
                            isValidMove: gameModel.validMoves.contains(where: { $0 == (row, col) }),
                            lightColor: gameModel.lightSquareColor,
                            darkColor: gameModel.darkSquareColor
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
struct ChessStatusView: View {
    @ObservedObject var gameModel: ChessGameModel
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // Turn indicator
                Text("Turn: \(gameModel.isWhiteTurn ? "White" : "Black")")
                    .foregroundColor(gameModel.isWhiteTurn ? .white : .black)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(8)
                    .background(gameModel.isWhiteTurn ? Color.black.opacity(0.7) : Color.white.opacity(0.7))
                    .cornerRadius(8)
                
                Spacer()
                
                // AI thinking indicator
                if gameModel.isAIThinking {
                    HStack {
                        Text("AI thinking")
                            .foregroundColor(.white)
                            .font(.subheadline)
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                }
                
                // Game mode indicator
                if gameModel.gameInProgress && gameModel.aiDifficulty != .none {
                    Text("AI: \(gameModel.aiDifficulty == .easy ? "Easy" : gameModel.aiDifficulty == .medium ? "Medium" : "Hard")")
                        .foregroundColor(.white)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(8)
                }
            }
            
            HStack {
                // Check/Checkmate indicator
                if gameModel.whiteInCheckmate || gameModel.blackInCheckmate {
                    Text("\(gameModel.whiteInCheckmate ? "White" : "Black") in Checkmate!")
                        .foregroundColor(.red)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                } else if gameModel.whiteInCheck || gameModel.blackInCheck {
                    Text("\(gameModel.whiteInCheck ? "White" : "Black") in Check!")
                        .foregroundColor(.red)
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding()
    }
}

// Winner announcement view
struct ChessWinnerView: View {
    let winner: ChessPieceColor
    let isCheckmate: Bool
    
    var body: some View {
        VStack {
            Text("\(winner == .white ? "White" : "Black") Wins!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(winner == .white ? .white : .black)
            
            if isCheckmate {
                Text("Checkmate!")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.top, 5)
            }
        }
        .padding()
        .background(winner == .white ? Color.black.opacity(0.7) : Color.white.opacity(0.7))
        .cornerRadius(10)
        .shadow(radius: 5)
    }
}

// Game options modal view
struct ChessGameOptionsModalView: View {
    @ObservedObject var gameModel: ChessGameModel
    @State private var selectedMode: ChessAIDifficulty = .none
    
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
                    selectedMode = .easy
                }) {
                    HStack {
                        Image(systemName: selectedMode == .easy ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMode == .easy ? .blue : .gray)
                        
                        VStack(alignment: .leading) {
                            Text("Easy AI")
                                .font(.headline)
                            Text("Play against a beginner level AI")
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
                            Text("Medium AI")
                                .font(.headline)
                            Text("Play against an intermediate level AI")
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
                    selectedMode = .hard
                }) {
                    HStack {
                        Image(systemName: selectedMode == .hard ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedMode == .hard ? .blue : .gray)
                        
                        VStack(alignment: .leading) {
                            Text("Hard AI")
                                .font(.headline)
                            Text("Play against an advanced level AI")
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
                gameModel.setAIDifficulty(selectedMode)
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

// Main chess view
struct ChessView: View {
    @StateObject private var gameModel = ChessGameModel()
    
    // Board background color
    private let boardBackgroundColor = Color(red: 0.1, green: 0.1, blue: 0.3) // Dark blue
    
    var body: some View {
        ZStack {
            // Background
            boardBackgroundColor
                .ignoresSafeArea()
            
            VStack {
                // Game status
                ChessStatusView(gameModel: gameModel)
                
                // Chess board
                ChessBoardView(gameModel: gameModel)
                
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
                .padding(.bottom, 5)
                
                Spacer(minLength: 0)
            }
            
            // Winner alert
            if let winner = gameModel.winner {
                ChessWinnerView(
                    winner: winner,
                    isCheckmate: winner == .white ? gameModel.blackInCheckmate : gameModel.whiteInCheckmate
                )
                .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
            }
            
            // Game options modal
            if gameModel.showGameOptionsModal {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .overlay(
                        ChessGameOptionsModalView(gameModel: gameModel)
                    )
            }
        }
    }
}

#Preview {
    ChessView()
} 

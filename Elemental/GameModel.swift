import Combine
import Foundation
import SwiftUI
import UIKit

class GameModel: ObservableObject {
    
    @Published var board: [[ElementType?]]
    @Published var particles: [Particle] = []
    @Published var isGameOver: Bool = false
    @Published var levelName: String = "Default"
    
    @Published var warpTransitionProgress: CGFloat = 0.0
    private(set) var warpTransitionPosition: Position? = nil
    private var displayLink: CADisplayLink?
    
    @Published private(set) var highScore: Int = 0
    private(set) var score: Int = 0
    
    private let allowedElements: [ElementType]
    private let customElements: [ElementType?]?
    private var initialState: (board: [[ElementType?]], score: Int)?
    private var previousState: (board: [[ElementType?]], score: Int)?
    private var isReset: Bool = false
    
    
    let level: Int
    
    init(level: Int, levelName: String, rows: Int, cols: Int, allowedElements: [ElementType], customElements: [ElementType?]? = nil) {
        self.allowedElements = allowedElements
        self.customElements = customElements
        self.level = level
        self.levelName = levelName
        board = Array(repeating: Array(repeating: nil, count: cols), count: rows)
        generateRandomElements()
        checkGameOver()
        initialState = (board: board, score: score)
        loadHighScore()
    }
    
    private func generateRandomElements() {
        if let customElements = customElements {
            for row in 0..<board.count {
                for col in 0..<board[row].count {
                    let index = (row * board[row].count + col) % customElements.count
                    board[row][col] = customElements[index]
                }
            }
        } else {
            for row in 0..<board.count {
                for col in 0..<board[row].count {
                    board[row][col] = allowedElements.randomElement()
                }
            }
        }
    }
    
    func saveHighScore() {
        UserDefaults.standard.set(highScore, forKey: "highScore_level_\(level)")
    }
    
    func loadHighScore() {
        highScore = UserDefaults.standard.integer(forKey: "highScore_level_\(level)")
    }
    
    func newGame() {
        score = 0
        generateRandomElements()
        initialState = (board: board, score: score)
        checkGameOver()
    }
    
    func resetGame() {
        guard let initState = initialState else { return }
        board = initState.board
        score = initState.score
        checkGameOver()
        isReset = true
    }
    
    func undoLastTap() {
        if isReset { return }
        guard let prevState = previousState else { return }
        board = prevState.board
        score = prevState.score
        checkGameOver()
    }
    
    func isCellEmpty(row: Int, col: Int) -> Bool {
        return board[row][col] == ElementType.empty || board[row][col] == nil
    }
    
    func runWarpTransitionAnimation(from sourceImage: UIImage, to targetImage: UIImage, at position: Position) {
        warpTransitionProgress = 0.0
        warpTransitionPosition = position
        let displayLink = CADisplayLink(target: self, selector: #selector(updateWarpTransition))
        displayLink.preferredFramesPerSecond = 60
        self.displayLink = displayLink
        displayLink.add(to: .main, forMode: .common)
    }
    
    @objc func updateWarpTransition(displayLink: CADisplayLink) {
        let deltaTime = CGFloat(displayLink.duration)
        warpTransitionProgress += deltaTime
        if warpTransitionProgress >= 1.0 {
            warpTransitionProgress = 1.0
            displayLink.invalidate()
            displayLink.remove(from: .main, forMode: .common)
            self.displayLink = nil
        }
    }
    
    func getWarpedImage() -> UIImage? {
        guard let sourceImage = ElementType.wood.image().ciImage, let targetImage = ElementType.fire.image().ciImage else {
            return nil
        }

        let transitionFilter = CIFilter(name: "CIDissolveTransition")!
        transitionFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        transitionFilter.setValue(targetImage, forKey: kCIInputTargetImageKey)
        transitionFilter.setValue(warpTransitionProgress, forKey: kCIInputTimeKey)

        guard let outputImage = transitionFilter.outputImage else {
            return nil
        }

        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
    
    func generateParticles(sourceRow: Int, sourceCol: Int, targetRow: Int, targetCol: Int, interaction: ElementType) {
        
        let cellSpacing = UIScreen.main.bounds.width / 32
        let cellSize = UIScreen.main.bounds.width / 8
        let sourcePosX = CGFloat(sourceCol) * (cellSize + cellSpacing) + cellSize / 2
        let sourcePosY = CGFloat(sourceRow) * (cellSize + cellSpacing) + cellSize / 2
        let sourcePosition = CGPoint(x: sourcePosX, y: sourcePosY)
        let targetPosX = CGFloat(targetCol) * (cellSize + cellSpacing) + cellSize / 2
        let targetPosY = CGFloat(targetRow) * (cellSize + cellSpacing) + cellSize / 2
        let targetPosition = CGPoint(x: targetPosX, y: targetPosY)
        let particleCount = 10
        let color: Color

        switch interaction {
        case .stone:
            color = Color.orange.opacity(Double.random(in: 0.4...1))
        case .fire:
            color = Color.red.opacity(Double.random(in: 0.4...1))
        case .water:
            color = Color.blue.opacity(Double.random(in: 0.4...1))
        case .earth:
            color = Color.black.opacity(Double.random(in: 0.4...1))
        case .air:
            color = Color.red.opacity(Double.random(in: 0.4...1))
        case .clay:
            color = Color.brown.opacity(Double.random(in: 0.4...1))
        default:
            color = Color.gray.opacity(Double.random(in: 0.4...1))
        }

        for _ in 0..<particleCount {
            let offsetX1 = CGFloat.random(in: -5...5)
            let offsetY1 = CGFloat.random(in: -5...5)
            let offsetX2 = CGFloat.random(in: -15...15)
            let offsetY2 = CGFloat.random(in: -15...15)
            let sourcePositionJittered = CGPoint(x: sourcePosition.x + offsetX1, y: sourcePosition.y + offsetY1)
            let targetPositionJittered = CGPoint(x: targetPosition.x + offsetX2, y: targetPosition.y + offsetY2)
            let particle = Particle(sourcePosition: sourcePositionJittered, targetPosition: targetPositionJittered, color: color)
            particles.append(particle)
        }
    }

    func removeParticles() {
        particles = []
    }
    
    private func getAdjacentIndices(row: Int, col: Int) -> [(Int, Int)] {
        var adjacentIndices = [(Int, Int)]()
        let offsets = [
            (-1, -1), (-1, 0), (-1, 1),
            (0, -1),           (0, 1),
            (1, -1),  (1, 0),  (1, 1)
        ]

        for (dy, dx) in offsets {
            let newRow = row + dy
            let newCol = col + dx
            if newRow >= 0 && newRow < board.count && newCol >= 0 && newCol < board[row].count {
                adjacentIndices.append((newRow, newCol))
            }
        }

        return adjacentIndices
    }
    
    private func getConnectedPots(row: Int, col: Int, visited: inout Set<Position>) -> Set<Position> {
        let currentPosition = Position(row: row, col: col)
        var connectedPots: Set<Position> = [currentPosition]
        let adjacentIndices = getAdjacentIndices(row: row, col: col)

        for (r, c) in adjacentIndices {
            let newPos = Position(row: r, col: c)
            if !visited.contains(newPos) && board[r][c] == .pot {
                visited.insert(newPos)
                connectedPots.formUnion(getConnectedPots(row: r, col: c, visited: &visited))
            }
        }

        return connectedPots
    }
    
    private func getChainedCoinPositions(connectedPots: Set<Position>, start: Position) -> [Position] {
        var queue: [Position] = [start]
        var visited: Set<Position> = [start]
        var orderedPositions: [Position] = []
        
        while !queue.isEmpty {
            let currentPosition = queue.removeFirst()
            orderedPositions.append(currentPosition)
            let adjacentIndices = getAdjacentIndices(row: currentPosition.row, col: currentPosition.col)
            
            for (r, c) in adjacentIndices {
                let newPos = Position(row: r, col: c)
                if connectedPots.contains(newPos) && !visited.contains(newPos) {
                    visited.insert(newPos)
                    queue.append(newPos)
                }
            }
        }
        
        return orderedPositions
    }

    func canMakeFire(row: Int, col: Int) -> Bool {
        let adjacentIndices = getAdjacentIndices(row: row, col: col)
        for (r, c) in adjacentIndices {
            if (board[row][col] == .air && board[r][c] == .fire) || (board[row][col] == .fire && board[r][c] == .air) || (board[row][col] == .stone && board[r][c] == .wood) {
                return true
            }
        }
        return false
    }
    
    func canExtinguishFire(row: Int, col: Int) -> Bool {
        let adjacentIndices = getAdjacentIndices(row: row, col: col)
        for (r, c) in adjacentIndices {
            if (board[row][col] == .fire && board[r][c] == .water) || (board[row][col] == .water && board[r][c] == .fire) {
                return true
            }
        }
        return false
    }

    func canMakeClay(row: Int, col: Int) -> Bool {
        let adjacentIndices = getAdjacentIndices(row: row, col: col)
        for (r, c) in adjacentIndices {
            if (board[row][col] == .earth && board[r][c] == .water) || (board[row][col] == .water && board[r][c] == .earth) {
                return true
            }
        }
        return false
    }

    func canMakePot(row: Int, col: Int) -> Bool {
        let adjacentIndices = getAdjacentIndices(row: row, col: col)
        for (r, c) in adjacentIndices {
            if (board[row][col] == .fire && board[r][c] == .clay) || (board[row][col] == .clay && board[r][c] == .fire) {
                return true
            }
        }
        return false
    }

    func canMakeCoin(row: Int, col: Int) -> Bool {
        if board[row][col] != .pot {
            return false
        }
        var visited: Set<Position> = [Position(row: row, col: col)]
        let connectedPots = getConnectedPots(row: row, col: col, visited: &visited)
        if connectedPots.count >= 3 {
            return true
        }
        return false
    }

    func checkGameOver() {
        var hasPossibleMoves = false
        for row in 0..<board.count {
            for col in 0..<board[row].count {
                if canMakeFire(row: row, col: col) || canExtinguishFire(row: row, col: col) || canMakeClay(row: row, col: col) || canMakePot(row: row, col: col) || canMakeCoin(row: row, col: col) {
                    hasPossibleMoves = true
                    break
                }
            }
            if hasPossibleMoves {
                break
            }
        }
        isGameOver = !hasPossibleMoves
        if isGameOver {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.highScore = max(self.highScore, self.score)
                self.saveHighScore()
                self.removeParticles()
            }
        }
    }

    private func delayedConvertToCoin(positions: [Position], delay: Double, points: Int, completion: @escaping () -> Void) {
        guard !positions.isEmpty else {
            completion()
            return
        }
        
        let position = positions[0]
        let currentDelay = positions.count == 1 ? 0.0 : delay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + currentDelay) { [weak self] in
            guard let self = self else { return }
            self.board[position.row][position.col] = .coin
            self.score += points
            self.delayedConvertToCoin(positions: Array(positions.dropFirst()), delay: delay, points: points, completion: completion)
        }
    }
    
    func onElementTapped(at row: Int, col: Int) {
        previousState = (board: board, score: score)
        let currentElement = board[row][col]
        let adjacentIndices = getAdjacentIndices(row: row, col: col)
        var pointsEarned = 0
        var coinPositions: [Position] = []
        var firePositions: [(Int, Int)] = []
        var airToFireConversion = false
        
        var isFirstIteration = true
        var iterationDelay: Double = 0.0
        let delayStep: Double = 0.0
        
        for (r, c) in adjacentIndices {
            _ = isFirstIteration ? 0.0 : iterationDelay
            isFirstIteration = false
            DispatchQueue.main.asyncAfter(deadline: .now() + iterationDelay) {
                switch currentElement {
                case .stone:
                    if self.board[r][c] == .wood {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .stone)
                        self.runWarpTransitionAnimation(from: ElementType.wood.image(), to: ElementType.fire.image(), at: Position(row: r, col: c))
                        self.board[r][c] = .fire
                        firePositions.append((r, c))
                        pointsEarned += 1
                    }
                case .air:
                    if self.board[r][c] == .fire {
                        self.generateParticles(sourceRow: r, sourceCol: c, targetRow: row, targetCol: col, interaction: .air)
                        firePositions.append((row, col))
                        airToFireConversion = true
                    }
                case .earth:
                    if self.board[r][c] == .water {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .earth)
                        self.board[row][col] = .clay
                        self.board[r][c] = .clay
                        pointsEarned += 1
                    }
                case .water:
                    if self.board[r][c] == .fire {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .water)
                        self.board[r][c] = .fire2fire_out
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.board[r][c] = .fire_out
                        }
                        self.board[r][c] = .fire_out
                        pointsEarned += 1
                    } else if self.board[r][c] == .earth {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .water)
                        self.board[row][col] = .clay
                        self.board[r][c] = .clay
                        pointsEarned += 1
                    }
                case .fire:
                    if self.board[r][c] == .clay {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .fire)
                        self.board[row][col] = .pot
                        self.board[r][c] = .pot
                        pointsEarned += 1
                    } else if self.board[r][c] == .air {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .fire)
                        firePositions.append((r, c))
                        airToFireConversion = true
                    }
                case .clay:
                    if self.board[r][c] == .fire {
                        self.generateParticles(sourceRow: row, sourceCol: col, targetRow: r, targetCol: c, interaction: .clay)
                        self.board[row][col] = .pot
                        self.board[r][c] = .pot
                        pointsEarned += 1
                    }
                case .pot:
                    var visited: Set<Position> = [Position(row: row, col: col)]
                    let connectedPots = self.getConnectedPots(row: row, col: col, visited: &visited)
                    if connectedPots.count >= 3 {
                        coinPositions = self.getChainedCoinPositions(connectedPots: connectedPots, start: Position(row: row, col: col))
                    }
                default:
                    break
                }
                DispatchQueue.main.async {
                    self.score += pointsEarned
                    pointsEarned = 0
                }
            }
            
            iterationDelay += delayStep
            
        }
            
        DispatchQueue.main.asyncAfter(deadline: .now() + iterationDelay) {
            for (r, c) in firePositions {
                self.board[r][c] = .fire
            }
            
            if airToFireConversion {
                pointsEarned += 1
            }
            
            if !coinPositions.isEmpty {
                self.delayedConvertToCoin(positions: coinPositions, delay: 0.05, points: 5) { [weak self] in
                    self?.checkGameOver()
                }
            } else {
                self.checkGameOver()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + iterationDelay + 2) {
            self.checkGameOver()
            self.isReset = false
        }
        
    }

}

struct Position: Hashable {
    let row: Int
    let col: Int
}

struct Particle: Identifiable, Equatable {
    let id: UUID
    let sourcePosition: CGPoint
    let targetPosition: CGPoint
    let color: Color
    var opacity: Double
    
    init(id: UUID = UUID(), sourcePosition: CGPoint, targetPosition: CGPoint, color: Color, opacity: Double = 1.0) {
        self.id = id
        self.sourcePosition = sourcePosition
        self.targetPosition = targetPosition
        self.color = color
        self.opacity = opacity
    }

    static func == (lhs: Particle, rhs: Particle) -> Bool {
        lhs.id == rhs.id
    }
}

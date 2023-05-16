import SwiftUI
import Combine
import GoogleMobileAds
import UIKit
import CoreImage

struct GameBoardView: View {
    @Environment(\.preferredColorScheme) var colorScheme
    @ObservedObject var viewModel: GameModel
    @State private var cancellables = Set<AnyCancellable>()

    let onNextLevel: (() -> Void)?
    let onPreviousLevel: (() -> Void)?
    let showNewButton: Bool
    let cellSize = UIScreen.main.bounds.width / 8
    let cellSpacing = UIScreen.main.bounds.width / 32

    var body: some View {
        let boardWidth = CGFloat(viewModel.board[0].count) * cellSize + CGFloat(viewModel.board[0].count - 1) * cellSpacing
        let boardHeight = CGFloat(viewModel.board.count) * cellSize + CGFloat(viewModel.board.count - 1) * cellSpacing
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                VStack(alignment: .center) {
                    StatusBarView(viewModel: viewModel)
                    ZStack(alignment: .center) {
                        LinesView(rows: viewModel.board.count, cols: viewModel.board[0].count, cellSize: cellSize, cellSpacing: cellSpacing, lineColorHex: "#cccccc", diagonalLineColorHex: "#f0f0f0", lineWidth: 10, viewModel: viewModel)
                            .frame(width: boardWidth, height: boardHeight)
                        GridView(viewModel: viewModel, cellSize: cellSize, cellSpacing: cellSpacing)
                        ParticleView(particles: $viewModel.particles, size: geometry.size)
                    }
                    .frame(width: boardWidth, height: boardHeight)
                    WarpedImageView(viewModel: viewModel, cellSize: cellSize, cellSpacing: cellSpacing)
                    BottomButtonsView(viewModel: viewModel)
                }
                
                if viewModel.isGameOver {
                    GameOverView(score: viewModel.score, highScore: viewModel.highScore, currentLevel: viewModel.level, onNextLevel: {
                        viewModel.newGame()
                        viewModel.isGameOver = false
                        onNextLevel?()
                    }, onPreviousLevel: {
                        viewModel.newGame()
                        viewModel.isGameOver = false
                        onPreviousLevel?()
                    }, onRestart: {
                        viewModel.resetGame()
                        viewModel.isGameOver = false
                    }, onNew: {
                        viewModel.newGame()
                        viewModel.isGameOver = false
                    }, showNewButton: showNewButton)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .preferredColorScheme(colorScheme)
        }
        Spacer()
        AdBannerView(adSize: GADAdSizeFromCGSize(CGSize(width: UIScreen.main.bounds.width, height: 120)))
            .frame(width: UIScreen.main.bounds.width, height: 120)
    }

}

struct StatusBarView: View {
    @ObservedObject var viewModel: GameModel

    var body: some View {
        VStack {
            HStack {
                Text("Level \(viewModel.level):")
                    .defaultFont()
                    .fontWeight(.bold)
            }
            HStack {
                Text("\(viewModel.levelName)")
                    .defaultFont()
                    .fontWeight(.bold)
            }
            HStack {
                Text("High score ")
                    .defaultFont()
                Image(ElementType.coin.imageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text("\(viewModel.highScore)")
                    .defaultFont()
            }
            HStack {
                Text("Score ")
                    .defaultFont()
                Image(ElementType.coin.imageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text("\(viewModel.score)")
                    .defaultFont()
            }
        }
    }
}

struct GridView: View {
    @ObservedObject var viewModel: GameModel
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<viewModel.board.count, id: \.self) { row in
                HStack(spacing: cellSpacing) {
                    ForEach(0..<viewModel.board[row].count, id: \.self) { col in
                        GridCellView(element: viewModel.board[row][col], cellSize: cellSize) {
                            viewModel.onElementTapped(at: row, col: col)
                        }
                    }
                }
            }
        }
    }
}

struct WarpedImageView: View {
    @ObservedObject var viewModel: GameModel
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    var body: some View {
        Image(uiImage: viewModel.getWarpedImage() ?? UIImage())
            .opacity(viewModel.warpTransitionProgress > 0 ? 1 : 0)
            .position(x: CGFloat(viewModel.warpTransitionPosition?.col ?? 0) * cellSize + CGFloat(viewModel.warpTransitionPosition?.col ?? 0) * cellSpacing + cellSize / 2,
                      y: CGFloat(viewModel.warpTransitionPosition?.row ?? 0) * cellSize + CGFloat(viewModel.warpTransitionPosition?.row ?? 0) * cellSpacing + cellSize / 2)
    }
}

struct BottomButtonsView: View {
    @ObservedObject var viewModel: GameModel

    var body: some View {
        HStack {
            Button(action: {
                viewModel.undoLastTap()
            }) {
                Text("Undo")
                    .defaultFont()
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(0)
            }
            
            Button(action: {
                viewModel.resetGame()
            }) {
                Text("Reset")
                    .defaultFont()
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(0)
            }
            
            if viewModel.level > 4 {
                Button(action: {
                    viewModel.newGame()
                }) {
                    Text("New")
                        .defaultFont()
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(0)
                }
            }
        }
        .padding()
    }
}


struct GridCellView: View {
    var element: ElementType?
    let cellSize: CGFloat
    let onTapped: () -> Void
    
    init(element: ElementType?, cellSize: CGFloat, onTapped: @escaping () -> Void) {
        self.element = element
        self.cellSize = cellSize
        self.onTapped = onTapped
    }
    
    var body: some View {
        GeometryReader { geometry in
            Group {
                if let element = element {
                    Image(element.imageName())
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: cellSize, height: cellSize)
                        .border(element == .empty ? Color.clear : Color(hex: "#cccccc"), width: 2)
                        .onTapGesture {
                            onTapped()
                        }
                } else {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.clear)
                        .frame(width: cellSize, height: cellSize)
                        .border(Color.black, width: 0.3)
                }
            }
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

struct GameOverView: View {
    let score: Int
    let highScore: Int
    let onRestart: () -> Void
    let onNew: () -> Void
    let currentLevel: Int
    let onNextLevel: () -> Void
    let onPreviousLevel: () -> Void
    let showNewButton: Bool
    
    init(score: Int, highScore: Int, currentLevel: Int, onNextLevel: @escaping () -> Void, onPreviousLevel: @escaping () -> Void, onRestart: @escaping () -> Void, onNew: @escaping () -> Void, showNewButton: Bool) {
        self.score = score
        self.highScore = highScore
        self.currentLevel = currentLevel
        self.onNextLevel = onNextLevel
        self.onPreviousLevel = onPreviousLevel
        self.onRestart = onRestart
        self.onNew = onNew
        self.showNewButton = showNewButton
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
            VStack {
                Text("Nicely done!")
                    .defaultFont()
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                Text("Your score: \(score)")
                    .defaultFont()
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("High score: \(highScore)")
                    .defaultFont()
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                HStack {
                    
                    if currentLevel > 1 {
                        Button(action: onPreviousLevel) {
                            Text("Back")
                                .defaultFont()
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(0)
                        }
                    }
                    
                    Button(action: onRestart) {
                        Text("Retry")
                            .defaultFont()
                            .fontWeight(.bold)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(0)
                    }
                    
                    if showNewButton {
                        Button(action: onNew) {
                            Text("New")
                                .defaultFont()
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(0)
                        }
                    }
                    
                    if currentLevel < 9 {
                        Button(action: onNextLevel) {
                            Text("Next")
                                .defaultFont()
                                .fontWeight(.bold)
                                .padding()
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(0)
                        }
                    }
                }
            }
        }
    }
}


struct ParticleView: View {
    @Binding var particles: [Particle]
    let size: CGSize

    @State private var animations: [UUID: ParticleAnimation] = [:]

    private func triggerAnimation(particleId: UUID) {
        animations[particleId] = ParticleAnimation(progress: 0)

        withAnimation(.linear(duration: 0.5)) {
            animations[particleId]?.progress = 1
        }
    }
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                RoundedRectangle(cornerRadius: 2)
                    .fill(particle.color)
                    .opacity(animations[particle.id]?.progress == 1 ? 0.0 : 1.0)
                    .frame(width: 6, height: 6)
                    .modifier(ParticleAnimationModifier(animation: animations[particle.id] ?? ParticleAnimation(progress: 0),
                                                        sourcePosition: particle.sourcePosition,
                                                        targetPosition: particle.targetPosition))
                    .onAppear {
                        triggerAnimation(particleId: particle.id)
                    }
            }
        }
    }
}



struct ParticleAnimation: Animatable {
    var progress: CGFloat = 0
    
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
}

struct ParticleAnimationModifier: AnimatableModifier {
    var animation: ParticleAnimation
    let sourcePosition: CGPoint
    let targetPosition: CGPoint
    
    var animatableData: ParticleAnimation {
        get { animation }
        set { animation = newValue }
    }
    
    func body(content: Content) -> some View {
        let position = CGPoint(x: sourcePosition.x + (targetPosition.x - sourcePosition.x) * animation.progress,
                               y: sourcePosition.y + (targetPosition.y - sourcePosition.y) * animation.progress)
        return content
            .position(position)
    }
}



struct LinesView: View {
    let rows: Int
    let cols: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let lineColorHex: String
    let diagonalLineColorHex: String
    let lineWidth: CGFloat
    let viewModel: GameModel

    private var lineColor: Color {
        return Color(hex: lineColorHex)
    }
    
    private var diagonalLineColor: Color {
        return Color(hex: diagonalLineColorHex)
    }

    private func centerPosition(forRow row: Int, col: Int) -> CGPoint {
        let x = CGFloat(col) * (cellSize + cellSpacing) + cellSize / 2
        let y = CGFloat(row) * (cellSize + cellSpacing) + cellSize / 2
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let center = centerPosition(forRow: row, col: col)

                        if col < cols - 1 && !viewModel.isCellEmpty(row: row, col: col) && !viewModel.isCellEmpty(row: row, col: col + 1) {
                            let rightCenter = centerPosition(forRow: row, col: col + 1)
                            path.move(to: center)
                            path.addLine(to: rightCenter)
                        }

                        if row < rows - 1 && !viewModel.isCellEmpty(row: row, col: col) && !viewModel.isCellEmpty(row: row + 1, col: col) {
                            let bottomCenter = centerPosition(forRow: row + 1, col: col)
                            path.move(to: center)
                            path.addLine(to: bottomCenter)
                        }
                    }
                }
            }
            .stroke(lineColor, lineWidth: lineWidth)
            
            Path { path in
                for row in 0..<rows {
                    for col in 0..<cols {
                        let center = centerPosition(forRow: row, col: col)

                        if row < rows - 1 && col < cols - 1 && !viewModel.isCellEmpty(row: row, col: col) && !viewModel.isCellEmpty(row: row + 1, col: col + 1) {
                            let diagonalRightDownCenter = centerPosition(forRow: row + 1, col: col + 1)
                            path.move(to: center)
                            path.addLine(to: diagonalRightDownCenter)
                        }

                        if row < rows - 1 && col > 0 && !viewModel.isCellEmpty(row: row, col: col) && !viewModel.isCellEmpty(row: row + 1, col: col - 1) {
                            let diagonalLeftDownCenter = centerPosition(forRow: row + 1, col: col - 1)
                            path.move(to: center)
                            path.addLine(to: diagonalLeftDownCenter)
                        }
                    }
                }
            }
            .stroke(diagonalLineColor, lineWidth: lineWidth)
        }
    }
}


extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0

        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.index(after: hex.startIndex)
        }

        scanner.scanHexInt64(&rgbValue)

        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

import SwiftUI



struct LevelOverview: View {
    @Environment(\.preferredColorScheme) var colorScheme
    @State private var selectedLevel: IdentifiableInt?
    @State private var isGameOver: Bool = false
    
    struct IdentifiableInt: Identifiable {
        let id = UUID()
        let value: Int
    }
    
    var body: some View {
        NavigationView {
            VStack {
                FlipView(source: "wood", target: "fire")
                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.05)
                Text("elemental")
                    .font(Font.custom("Courier-Bold", size: 32))
                    .fontWeight(.bold)
                HStack {
                    Spacer()
                    VStack {
                        Image(ElementType.fire.imageName())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        Text("fire")
                            .defaultFont()
                    }
                    Spacer()
                    VStack {
                        Image(ElementType.water.imageName())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        Text("water")
                            .defaultFont()
                    }
                    Spacer()
                    VStack {
                        Image(ElementType.earth.imageName())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        Text("earth")
                            .defaultFont()
                    }
                    Spacer()
                    VStack {
                        Image(ElementType.air.imageName())
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        Text("air")
                            .defaultFont()
                    }
                    Spacer()
                }
                
                ScrollView {
                    HStack {
                        Spacer()
                        VStack(spacing: 20) {
                            ForEach(0..<9) { index in
                                levelButton(level: index + 1)
                            }
                        }
                        .padding()
                        Spacer()
                    }
                }
            }
            .preferredColorScheme(colorScheme)
            .sheet(item: $selectedLevel) { identifiableLevel in
                gameBoardViewForLevel(level: identifiableLevel.value)
            }
        }
    }
    
    let gameModels: [GameModel] = [
        GameModel(level: 1, levelName: "Tap air elements to\nspread some fire!", rows: 5, cols: 5, allowedElements: [.empty, .stone, .wood], customElements: [
            .stone, .wood, .empty, .wood, .stone,
            .wood, .wood, .wood, .wood, .wood,
            .empty, .wood, .stone, .wood, .empty,
            .wood, .wood, .wood, .wood, .wood,
            .stone, .wood, .empty, .wood, .stone
        ]),
        GameModel(level: 2, levelName: "Put out fire with water!", rows: 5, cols: 5, allowedElements: [.empty, .fire, .water], customElements: [
            .water, .fire, .empty, .fire, .water,
            .fire, .fire, .fire, .fire, .fire,
            .empty, .fire, .water, .fire, .empty,
            .fire, .fire, .fire, .fire, .fire,
            .water, .fire, .empty, .fire, .water
        ]),
        GameModel(level: 3, levelName: "Mix water and earth\nto make clay!", rows: 5, cols: 5, allowedElements: [.empty, .water, .earth], customElements: [
            .water, .earth, .empty, .earth, .water,
            .earth, .earth, .water, .earth, .earth,
            .empty, .water, .earth, .water, .empty,
            .earth, .earth, .water, .earth, .earth,
            .water, .earth, .empty, .earth, .water
        ]),
        GameModel(level: 4, levelName: "Use fire and clay\nto form pots\nand sell them!", rows: 4, cols: 4, allowedElements: [.clay, .fire], customElements: [
            .fire, .clay, .clay, .fire,
            .clay, .fire, .fire, .clay,
            .clay, .fire, .fire, .clay,
            .fire, .clay, .clay, .fire
        ]),
        GameModel(level: 5, levelName: "You know everything now.\nUse the elements wisely.", rows: 5, cols: 5, allowedElements: [.earth, .water, .fire, .air]),
        GameModel(level: 6, levelName: "Random 6 x 6", rows: 6, cols: 6, allowedElements: [.earth, .water, .fire, .air]),
        GameModel(level: 7, levelName: "Random 7 x 6", rows: 7, cols: 6, allowedElements: [.earth, .water, .fire, .air]),
        GameModel(level: 8, levelName: "Random 8 x 6", rows: 8, cols: 6, allowedElements: [.earth, .water, .fire, .air]),
        GameModel(level: 9, levelName: "Random 9 x 6", rows: 9, cols: 6, allowedElements: [.earth, .water, .fire, .air]),
    ]
    
    private func nextLevel() {
        if let currentLevel = selectedLevel?.value, currentLevel < 9 {
            selectedLevel = IdentifiableInt(value: currentLevel + 1)
        }
    }
    
    private func previousLevel() {
        if let currentLevel = selectedLevel?.value, currentLevel > 1 {
            selectedLevel = IdentifiableInt(value: currentLevel - 1)
        }
    }
    
    private func levelButton(level: Int) -> some View {
        let gameModel = gameModels[level - 1]
        return Button(action: {
            selectedLevel = IdentifiableInt(value: level)
        }) {
            HStack {
                Text("Level \(level)   ")
                Image(ElementType.coin.imageName())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                Text("\(gameModel.highScore)")
            }
            .defaultFont()
            .padding()
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(0)
        }
        .border(Color.black, width: 1)
    }
    
    
    private func gameBoardViewForLevel(level: Int?) -> some View {
        switch level {
        case 1:
            return AnyView(GameBoardView(viewModel: gameModels[0], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: false))
        case 2:
            return AnyView(GameBoardView(viewModel: gameModels[1], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: false))
        case 3:
            return AnyView(GameBoardView(viewModel: gameModels[2], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: false))
        case 4:
            return AnyView(GameBoardView(viewModel: gameModels[3], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: false))
        case 5:
            return AnyView(GameBoardView(viewModel: gameModels[4], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: true))
        case 6:
            return AnyView(GameBoardView(viewModel: gameModels[5], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: true))
        case 7:
            return AnyView(GameBoardView(viewModel: gameModels[6], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: true))
        case 8:
            return AnyView(GameBoardView(viewModel: gameModels[7], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: true))
        case 9:
            return AnyView(GameBoardView(viewModel: gameModels[8], onNextLevel: nextLevel, onPreviousLevel: previousLevel, showNewButton: true))
        default:
            return AnyView(EmptyView())
        }
    }
}


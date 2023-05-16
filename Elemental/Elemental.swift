import SwiftUI

@main
struct ElementalApp: App {
    @Namespace private var appNamespace
    @State private var showStartScreen: Bool = true
    @State private var showLevelOverview: Bool = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showStartScreen {
                    StartScreen(namespace: appNamespace, showLevelOverview: $showLevelOverview)
                        .onDisappear {
                            withAnimation(.easeInOut(duration: 1.5)) {
                                showStartScreen = false
                            }
                        }
                }
                
                if showLevelOverview {
                    LevelOverview()
                        .environment(\.preferredColorScheme, .light)
                }
            }
            .defaultFont()
        }
    }
}


enum ElementType: String, CaseIterable {
    case empty, stone, wood, earth, water, fire, air, clay, pot, coin, fire_out, fire2fire_out
    
    func imageName() -> String {
        return rawValue
    }
    
    func image() -> UIImage {
        return UIImage(named: imageName())!
    }
}

struct PreferredColorSchemeKey: EnvironmentKey {
    static var defaultValue: ColorScheme = .light
}

extension EnvironmentValues {
    var preferredColorScheme: ColorScheme {
        get { self[PreferredColorSchemeKey.self] }
        set { self[PreferredColorSchemeKey.self] = newValue }
    }
}

extension View {
    func defaultFont() -> some View {
        self.environment(\.font, .init(Font.custom("Courier", size: UIFont.preferredFont(forTextStyle: .body).pointSize)))
    }
}

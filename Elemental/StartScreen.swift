import SwiftUI

struct StartScreen: View {
    let namespace: Namespace.ID
    @Binding var showLevelOverview: Bool
    @State private var animationAmount: CGFloat = 1
    @State private var opacityAmount: Double = 1
    @State private var showLevelsButton: Bool = false
    
    var body: some View {
        ZStack {
            RepeatingBackground(image: Image("LoadingScreenBG"))
            
            VStack {
                
                Spacer()
                
                .frame(height: UIScreen.main.bounds.height * 0.33)
                
                Text("elemental")
                    .font(Font.custom("Courier-Bold", size: 32))
                    .fontWeight(.bold)
                    .scaleEffect(animationAmount)
                    .foregroundColor(.white)
                    .shadow(color: .black, radius: 3, x: 0, y: 0)
                    .opacity(opacityAmount)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 1)) {
                            animationAmount = 1.2
                        }
                    }
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLevelOverview = true
                    }
                }) {
                    Text("Start Game")
                        .defaultFont()
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(0)
                }
                .opacity(showLevelsButton ? 1 : 0)
                
                Spacer()
            
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.easeOut(duration: 1.5)) {
                    showLevelsButton = true
                }
            }
        }
    }
}

struct RepeatingBackground: View {
    let image: Image
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                imageStitch
                    .frame(width: geometry.size.width)
                    .offset(y: offset)
                    .clipped()
                imageStitch
                    .frame(width: geometry.size.width)
                    .offset(y: offset - geometry.size.height * 1.535)
                    .clipped()
            }
            .edgesIgnoringSafeArea(.all)
            .onAppear {
                withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                    offset = geometry.size.height * 1.535
                }
            }
        }
    }
    
    var imageStitch: some View {
        VStack(spacing: 0) {
            image
                .resizable()
                .scaledToFill()
            image
                .resizable()
                .scaledToFill()
        }
    }
}


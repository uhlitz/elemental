import SwiftUI

struct ImageTransitionExample: View {
    @State private var showFireImage = false
    @State private var woodOpacity = 1.0
    
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                withAnimation(.easeIn(duration: 0.5)) {
                    showFireImage.toggle()
                }
            }) {
                ZStack {
                    Image("wood")
                        .resizable()
                        .scaledToFit()
                        .rotation3DEffect(.degrees(showFireImage ? 90 : 0), axis: (x: 0, y: 1, z: 0))
                        .opacity(woodOpacity)
                        .onChange(of: showFireImage) { newValue in
                            if newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    woodOpacity = 0.0
                                }
                            } else {
                                woodOpacity = 1.0
                            }
                        }
                    
                    Image("fire")
                        .resizable()
                        .scaledToFit()
                        .rotation3DEffect(.degrees(showFireImage ? 0 : -90), axis: (x: 0, y: 1, z: 0))
                        .opacity(showFireImage ? 1.0 : 0.0)
                        .animation(showFireImage ? .easeOut(duration: 0.5).delay(0.5) : nil, value: showFireImage)
                }
            }
            Spacer()
        }
    }
}

struct ImageTransitionExample_Previews: PreviewProvider {
    static var previews: some View {
        ImageTransitionExample()
    }
}

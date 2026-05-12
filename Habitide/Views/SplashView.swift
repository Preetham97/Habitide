import SwiftUI

struct SplashView: View {
    @State private var iconScale: CGFloat = 0.85
    @State private var iconOpacity: Double = 0
    @State private var wordmarkOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 18) {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("Habitide")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .tracking(0.5)
                    .foregroundStyle(.white)
                    .opacity(wordmarkOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.78)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.45).delay(0.2)) {
                wordmarkOpacity = 1.0
            }
        }
    }
}

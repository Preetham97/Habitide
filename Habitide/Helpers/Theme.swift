import SwiftUI
import UIKit

enum Theme {
    static let cornerRadius: CGFloat = 18
    static let cardCornerRadius: CGFloat = 22
    static let tileCornerRadius: CGFloat = 4
}

extension Color {
    static let brandGreen = Color(red: 0.31, green: 0.78, blue: 0.47)
    static let brandOrange = Color(red: 0.98, green: 0.65, blue: 0.20)
    static let brandRed = Color(red: 0.95, green: 0.36, blue: 0.36)
    static let brandMuted = Color(.tertiarySystemFill)
}

enum Haptics {
    static func light() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }
    static func soft() {
        let g = UIImpactFeedbackGenerator(style: .soft)
        g.impactOccurred()
    }
    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }
}

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
}

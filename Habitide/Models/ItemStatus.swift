import SwiftUI

enum ItemStatus: Int, CaseIterable, Codable {
    case unlogged = -1
    case red = 0
    case orange = 1
    case green = 2

    var emoji: String {
        switch self {
        case .unlogged: "⬜️"
        case .red: "🟥"
        case .orange: "🟧"
        case .green: "🟩"
        }
    }

    var color: Color {
        switch self {
        case .unlogged: Color.brandMuted
        case .red: Color.brandRed
        case .orange: Color.brandOrange
        case .green: Color.brandGreen
        }
    }

    var label: String {
        switch self {
        case .unlogged: "—"
        case .red: "Off"
        case .orange: "Okay"
        case .green: "Great"
        }
    }

    var glyph: String {
        switch self {
        case .unlogged: "circle.dashed"
        case .red: "xmark"
        case .orange: "minus"
        case .green: "checkmark"
        }
    }
}

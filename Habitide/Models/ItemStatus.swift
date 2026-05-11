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
        case .unlogged: Color.gray.opacity(0.3)
        case .red: Color.red
        case .orange: Color.orange
        case .green: Color.green
        }
    }

    var label: String {
        switch self {
        case .unlogged: "—"
        case .red: "Bad"
        case .orange: "Average"
        case .green: "Good"
        }
    }
}

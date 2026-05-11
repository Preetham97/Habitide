import Foundation
import SwiftData

@Model
final class RoutineItem {
    var id: UUID
    var name: String
    var emoji: String
    var sortOrder: Int
    var routine: Routine?

    init(name: String, emoji: String, sortOrder: Int) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
    }
}

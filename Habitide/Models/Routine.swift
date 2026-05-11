import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem] = []

    init(name: String, isActive: Bool = true) {
        self.name = name
        self.createdAt = Date()
        self.isActive = isActive
    }

    var sortedItems: [RoutineItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }
}

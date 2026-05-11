import Foundation
import SwiftData

@Model
final class ItemLog {
    var itemID: UUID
    var itemName: String
    var itemEmoji: String
    var sortOrder: Int
    var statusRaw: Int
    var dayLog: DayLog?

    init(item: RoutineItem, status: ItemStatus = .unlogged) {
        self.itemID = item.id
        self.itemName = item.name
        self.itemEmoji = item.emoji
        self.sortOrder = item.sortOrder
        self.statusRaw = status.rawValue
    }

    var status: ItemStatus {
        get { ItemStatus(rawValue: statusRaw) ?? .unlogged }
        set { statusRaw = newValue.rawValue }
    }
}

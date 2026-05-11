import Foundation
import SwiftData

@Model
final class DayLog {
    @Attribute(.unique) var date: Date  // normalized to start-of-day
    var routineName: String

    @Relationship(deleteRule: .cascade, inverse: \ItemLog.dayLog)
    var itemLogs: [ItemLog] = []

    init(date: Date, routineName: String) {
        self.date = Calendar.current.startOfDay(for: date)
        self.routineName = routineName
    }
}

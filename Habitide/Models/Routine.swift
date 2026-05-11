import Foundation
import SwiftData

@Model
final class Routine {
    var name: String
    var createdAt: Date
    var isActive: Bool
    /// Bitmask: bit 0 = Sunday, bit 1 = Monday, ..., bit 6 = Saturday.
    /// (Matches Foundation Calendar.weekday convention where Sunday = 1.)
    var weekdayMask: Int = 0b1111111  // 127 = every day by default

    @Relationship(deleteRule: .cascade, inverse: \RoutineItem.routine)
    var items: [RoutineItem] = []

    init(name: String, isActive: Bool = true, weekdayMask: Int = 0b1111111) {
        self.name = name
        self.createdAt = Date()
        self.isActive = isActive
        self.weekdayMask = weekdayMask
    }

    var sortedItems: [RoutineItem] {
        items.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// `weekday` matches Calendar.component(.weekday, from:) — 1 = Sun ... 7 = Sat.
    func covers(weekday: Int) -> Bool {
        let bit = 1 << (weekday - 1)
        return (weekdayMask & bit) != 0
    }

    /// Compact human-readable label e.g. "Every day", "Mon–Fri", "Sat, Sun".
    var weekdaysLabel: String {
        if weekdayMask == 0 { return "No days" }
        if weekdayMask == 0b1111111 { return "Every day" }
        if weekdayMask == 0b0111110 { return "Mon–Fri" }
        if weekdayMask == 0b1000001 { return "Sat, Sun" }

        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let active = (0..<7).compactMap { (weekdayMask & (1 << $0)) != 0 ? symbols[$0] : nil }
        return active.joined(separator: ", ")
    }
}

extension Routine {
    /// Returns the routine that covers the given date's weekday.
    static func forDate(_ date: Date, in routines: [Routine]) -> Routine? {
        let weekday = Calendar.current.component(.weekday, from: date)
        return routines.first { $0.covers(weekday: weekday) }
    }
}

import Foundation

enum ScoreCalculator {
    /// Overall day status from logged items.
    /// - Each green = 2 pts, orange = 1, red = 0.
    /// - Returns green if average ≥ 1.5, red if average ≤ 0.5, otherwise orange.
    /// Examples: 4 orange + 2 green (avg 1.33) → orange. 5 green + 1 orange (avg 1.83) → green.
    static func overall(for logs: [ItemLog]) -> ItemStatus {
        let logged = logs.filter { $0.status != .unlogged }
        guard !logged.isEmpty else { return .unlogged }
        let total = logged.reduce(0) { $0 + $1.status.rawValue }
        let avg = Double(total) / Double(logged.count)
        if avg >= 1.5 { return .green }
        if avg <= 0.5 { return .red }
        return .orange
    }
}

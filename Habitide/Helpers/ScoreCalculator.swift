import Foundation

enum ScoreCalculator {
    /// Strict majority over logged items.
    /// - green if greens > oranges + reds
    /// - red if reds > greens + oranges
    /// - otherwise orange (including ties)
    static func overall(for logs: [ItemLog]) -> ItemStatus {
        let logged = logs.filter { $0.status != .unlogged }
        guard !logged.isEmpty else { return .unlogged }
        let greens = logged.filter { $0.status == .green }.count
        let oranges = logged.filter { $0.status == .orange }.count
        let reds = logged.filter { $0.status == .red }.count
        if greens > oranges + reds { return .green }
        if reds > greens + oranges { return .red }
        return .orange
    }
}

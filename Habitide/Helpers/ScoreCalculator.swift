import Foundation

enum ScoreCalculator {
    static func overall(for logs: [ItemLog]) -> ItemStatus {
        let logged = logs.filter { $0.status != .unlogged }
        guard !logged.isEmpty else { return .unlogged }
        let totalPoints = logged.reduce(0) { $0 + $1.status.rawValue }
        let maxPoints = logged.count * 2
        let percent = Double(totalPoints) / Double(maxPoints)
        if percent > 0.66 { return .green }
        if percent < 0.34 { return .red }
        return .orange
    }
}

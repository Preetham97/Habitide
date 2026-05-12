import Foundation
import SwiftUI

// MARK: - Aggregates

struct WeekBucket: Identifiable {
    let id = UUID()
    let startDate: Date
    let total: Int
    let greens: Int
    let oranges: Int
    let reds: Int
    var pct: Double { total == 0 ? 0 : Double(greens) / Double(total) }
}

struct ItemSummary: Identifiable {
    let id: UUID  // itemID
    let name: String
    let emoji: String
    let totalLogged: Int
    let green: Int
    let orange: Int
    let red: Int
    let currentStreak: Int    // consecutive days ending today with green
    let longestStreak: Int
    let deltaPct: Double?     // change vs previous-period (nil if no prior data)
    let recentStatuses: [ItemStatus]  // last 30 days, oldest → newest, .unlogged for missing
    let bestWeekday: Int?     // 1..7
    let worstWeekday: Int?

    var greenPct: Double {
        totalLogged == 0 ? 0 : Double(green) / Double(totalLogged)
    }
}

struct Headline: Identifiable {
    let id = UUID()
    let icon: String
    let tint: Color
    let title: String
    let detail: String
    let priority: Int
}

// MARK: - Engine

enum StatsEngine {
    private static let cal = Calendar.current

    // MARK: Filters

    static func logsInTrailing(_ days: Int, logs: [DayLog]) -> [DayLog] {
        guard let cutoff = cal.date(byAdding: .day, value: -days + 1, to: Date().startOfDay) else { return logs }
        return logs.filter { $0.date >= cutoff }
    }

    // MARK: Streaks

    /// Days in a row ending today where overall was at least 'orange' (i.e. logged + not red).
    /// Pass minimum: .green to count green-only streaks.
    static func overallStreak(logs: [DayLog], minimum: ItemStatus = .orange) -> Int {
        let byDate = Dictionary(uniqueKeysWithValues: logs.map { ($0.date.startOfDay, $0) })
        var d = Date().startOfDay
        var count = 0
        while let log = byDate[d] {
            let s = ScoreCalculator.overall(for: log.itemLogs)
            guard s.rawValue >= minimum.rawValue else { break }
            count += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return count
    }

    static func currentGreenStreak(itemID: UUID, logs: [DayLog]) -> Int {
        let byDate = Dictionary(uniqueKeysWithValues: logs.map { ($0.date.startOfDay, $0) })
        var d = Date().startOfDay
        var count = 0
        while let log = byDate[d],
              let il = log.itemLogs.first(where: { $0.itemID == itemID }) {
            guard il.status == .green else { break }
            count += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return count
    }

    static func longestGreenStreak(itemID: UUID, logs: [DayLog]) -> Int {
        let sorted = logs.sorted { $0.date < $1.date }
        var best = 0
        var current = 0
        for log in sorted {
            if let il = log.itemLogs.first(where: { $0.itemID == itemID }), il.status == .green {
                current += 1
                best = max(best, current)
            } else {
                current = 0
            }
        }
        return best
    }

    // MARK: Day-of-week patterns

    /// Returns greenPct for each weekday 1...7 (Sun..Sat). Only weekdays with at least 2 logged days appear.
    static func greenPctByWeekday(logs: [DayLog]) -> [Int: (pct: Double, count: Int)] {
        var greens: [Int: Int] = [:]
        var totals: [Int: Int] = [:]
        for log in logs {
            let overall = ScoreCalculator.overall(for: log.itemLogs)
            guard overall != .unlogged else { continue }
            let wd = cal.component(.weekday, from: log.date)
            totals[wd, default: 0] += 1
            if overall == .green { greens[wd, default: 0] += 1 }
        }
        var out: [Int: (pct: Double, count: Int)] = [:]
        for wd in 1...7 {
            let t = totals[wd, default: 0]
            if t >= 2 {
                out[wd] = (Double(greens[wd, default: 0]) / Double(t), t)
            }
        }
        return out
    }

    static func itemGreenPctByWeekday(itemID: UUID, logs: [DayLog]) -> [Int: Double] {
        var greens: [Int: Int] = [:]
        var totals: [Int: Int] = [:]
        for log in logs {
            guard let il = log.itemLogs.first(where: { $0.itemID == itemID }), il.status != .unlogged else { continue }
            let wd = cal.component(.weekday, from: log.date)
            totals[wd, default: 0] += 1
            if il.status == .green { greens[wd, default: 0] += 1 }
        }
        var out: [Int: Double] = [:]
        for wd in 1...7 where totals[wd, default: 0] >= 2 {
            out[wd] = Double(greens[wd, default: 0]) / Double(totals[wd, default: 0])
        }
        return out
    }

    // MARK: Weekly buckets

    static func weeklyBuckets(logs: [DayLog], weeks: Int) -> [WeekBucket] {
        var current = startOfWeek(for: Date())
        var buckets: [WeekBucket] = []
        for _ in 0..<weeks {
            let weekEnd = cal.date(byAdding: .day, value: 6, to: current)!
            let inWeek = logs.filter { $0.date >= current && $0.date <= weekEnd }
            var g = 0, o = 0, r = 0
            for log in inWeek {
                let s = ScoreCalculator.overall(for: log.itemLogs)
                switch s {
                case .green: g += 1
                case .orange: o += 1
                case .red: r += 1
                default: break
                }
            }
            buckets.append(WeekBucket(startDate: current, total: g + o + r, greens: g, oranges: o, reds: r))
            current = cal.date(byAdding: .day, value: -7, to: current)!
        }
        return buckets.reversed()
    }

    static func startOfWeek(for date: Date) -> Date {
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date.startOfDay
    }

    // MARK: Item summaries

    static func itemSummaries(logs: [DayLog], trailingDays: Int = 30) -> [ItemSummary] {
        let recentCutoff = cal.date(byAdding: .day, value: -trailingDays + 1, to: Date().startOfDay) ?? Date()
        let previousCutoff = cal.date(byAdding: .day, value: -2 * trailingDays + 1, to: Date().startOfDay) ?? Date()
        let recentLogs = logs.filter { $0.date >= recentCutoff }
        let prevLogs = logs.filter { $0.date >= previousCutoff && $0.date < recentCutoff }

        // Group itemLogs by itemID
        struct Bag {
            var name: String = ""
            var emoji: String = ""
            var statuses: [(date: Date, status: ItemStatus)] = []
        }
        var bags: [UUID: Bag] = [:]
        for log in recentLogs {
            for il in log.itemLogs where il.status != .unlogged {
                var bag = bags[il.itemID] ?? Bag()
                bag.name = il.itemName
                bag.emoji = il.itemEmoji
                bag.statuses.append((log.date, il.status))
                bags[il.itemID] = bag
            }
        }

        var summaries: [ItemSummary] = []
        for (id, bag) in bags {
            let g = bag.statuses.filter { $0.status == .green }.count
            let o = bag.statuses.filter { $0.status == .orange }.count
            let r = bag.statuses.filter { $0.status == .red }.count
            let total = g + o + r
            let recentPct = total > 0 ? Double(g) / Double(total) : 0

            // Previous-period pct for delta
            var prevTotal = 0, prevG = 0
            for log in prevLogs {
                if let il = log.itemLogs.first(where: { $0.itemID == id }), il.status != .unlogged {
                    prevTotal += 1
                    if il.status == .green { prevG += 1 }
                }
            }
            let delta: Double? = prevTotal >= 3
                ? recentPct - Double(prevG) / Double(prevTotal)
                : nil

            // Recent statuses array (oldest -> newest, .unlogged for missing days)
            var statusByDate: [Date: ItemStatus] = [:]
            for entry in bag.statuses {
                statusByDate[entry.date.startOfDay] = entry.status
            }
            var recent: [ItemStatus] = []
            for offset in (0..<trailingDays).reversed() {
                if let d = cal.date(byAdding: .day, value: -offset, to: Date().startOfDay) {
                    recent.append(statusByDate[d] ?? .unlogged)
                }
            }

            // Weekday best/worst
            let weekdayPcts = itemGreenPctByWeekday(itemID: id, logs: logs)
            let bestWd = weekdayPcts.max(by: { $0.value < $1.value })?.key
            let worstWd = weekdayPcts.min(by: { $0.value < $1.value })?.key

            summaries.append(ItemSummary(
                id: id,
                name: bag.name,
                emoji: bag.emoji,
                totalLogged: total,
                green: g,
                orange: o,
                red: r,
                currentStreak: currentGreenStreak(itemID: id, logs: logs),
                longestStreak: longestGreenStreak(itemID: id, logs: logs),
                deltaPct: delta,
                recentStatuses: recent,
                bestWeekday: bestWd,
                worstWeekday: worstWd
            ))
        }
        return summaries.sorted { $0.greenPct > $1.greenPct }
    }

    // MARK: Headlines

    static func headlines(logs: [DayLog]) -> [Headline] {
        let loggedDays = logs.filter { ScoreCalculator.overall(for: $0.itemLogs) != .unlogged }.count

        if loggedDays < 3 {
            return [Headline(
                icon: "sparkles",
                tint: .brandGreen,
                title: "Just getting started",
                detail: "Log at least 7 days to unlock patterns and insights.",
                priority: 100
            )]
        }

        var candidates: [Headline] = []

        // 1. Overall streak (any non-red logged day)
        let streak = overallStreak(logs: logs)
        if streak >= 3 {
            candidates.append(Headline(
                icon: "flame.fill",
                tint: .brandOrange,
                title: "\(streak)-day logging streak",
                detail: "You've checked in every day for \(streak) days.",
                priority: 60 + streak
            ))
        }

        // 2. All-green streak
        let greenStreak = overallStreak(logs: logs, minimum: .green)
        if greenStreak >= 3 {
            candidates.append(Headline(
                icon: "star.fill",
                tint: .brandGreen,
                title: "\(greenStreak) great days in a row",
                detail: "Every day this run was a 🟩.",
                priority: 80 + greenStreak
            ))
        }

        // 3. Day-of-week disparity
        let weekday = greenPctByWeekday(logs: logs)
        if let best = weekday.max(by: { $0.value.pct < $1.value.pct }),
           let worst = weekday.min(by: { $0.value.pct < $1.value.pct }),
           best.value.pct - worst.value.pct >= 0.30 {
            candidates.append(Headline(
                icon: "calendar",
                tint: .brandGreen,
                title: "Strongest on \(weekdayName(best.key))s",
                detail: "\(Int(best.value.pct * 100))% great vs \(Int(worst.value.pct * 100))% on \(weekdayName(worst.key))s.",
                priority: 50
            ))
        }

        // 4. Weekly trend
        let weeks = weeklyBuckets(logs: logs, weeks: 4)
        if weeks.count >= 2, let recent = weeks.last, recent.total >= 3 {
            let prevAvg = weeks.dropLast().filter { $0.total >= 3 }.map(\.pct).reduce(0, +) /
                Double(max(weeks.dropLast().filter { $0.total >= 3 }.count, 1))
            if recent.pct > prevAvg + 0.15 {
                candidates.append(Headline(
                    icon: "chart.line.uptrend.xyaxis",
                    tint: .brandGreen,
                    title: "This week's your best in a while",
                    detail: "\(Int(recent.pct * 100))% great so far — up from \(Int(prevAvg * 100))% recent average.",
                    priority: 75
                ))
            } else if recent.pct < prevAvg - 0.15 {
                candidates.append(Headline(
                    icon: "chart.line.downtrend.xyaxis",
                    tint: .brandRed,
                    title: "Slipping this week",
                    detail: "\(Int(recent.pct * 100))% great — down from \(Int(prevAvg * 100))% recent average.",
                    priority: 65
                ))
            }
        }

        // 5. Item movers
        let summaries = itemSummaries(logs: logs)
        if let mover = summaries
            .filter({ $0.deltaPct != nil })
            .max(by: { abs($0.deltaPct ?? 0) < abs($1.deltaPct ?? 0) }),
           let delta = mover.deltaPct,
           abs(delta) >= 0.20 {
            if delta > 0 {
                candidates.append(Headline(
                    icon: "arrow.up.right",
                    tint: .brandGreen,
                    title: "\(mover.emoji) \(mover.name) is up \(Int(delta * 100))%",
                    detail: "Compared to the previous 30 days.",
                    priority: 55
                ))
            } else {
                candidates.append(Headline(
                    icon: "arrow.down.right",
                    tint: .brandRed,
                    title: "\(mover.emoji) \(mover.name) has slipped \(Int(abs(delta) * 100))%",
                    detail: "Down from the previous 30 days.",
                    priority: 55
                ))
            }
        }

        // 6. Coverage milestone
        if loggedDays == 7 || loggedDays == 30 || loggedDays == 100 {
            candidates.append(Headline(
                icon: "checkmark.seal.fill",
                tint: .brandGreen,
                title: "\(loggedDays) days logged",
                detail: "Keep going — patterns get sharper with more data.",
                priority: 70
            ))
        }

        return Array(candidates.sorted { $0.priority > $1.priority }.prefix(3))
    }

    // MARK: Helpers

    static func weekdayName(_ wd: Int, abbreviated: Bool = false) -> String {
        let fmt = DateFormatter()
        let symbols = abbreviated ? fmt.shortWeekdaySymbols! : fmt.weekdaySymbols!
        return symbols[(wd - 1) % 7]
    }

    static func weekdayShort(_ wd: Int) -> String {
        let fmt = DateFormatter()
        return fmt.veryShortWeekdaySymbols[(wd - 1) % 7]
    }
}

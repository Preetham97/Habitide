import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var selectedLog: DayLog? = nil

    private let cal = Calendar.current
    private let tileSize: CGFloat = 14
    private let tileSpacing: CGFloat = 4

    // 365 days ending today, grouped into weeks (columns of 7)
    private var grid: [[Date]] {
        let today = Date().startOfDay
        guard let start = cal.date(byAdding: .day, value: -364, to: today) else { return [] }
        let firstWeekday = cal.firstWeekday  // 1 = Sun
        let startWeekday = cal.component(.weekday, from: start)
        let leadingBlanks = (startWeekday - firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        var d = start
        while d <= today {
            days.append(d)
            d = cal.date(byAdding: .day, value: 1, to: d) ?? d
        }
        while days.count % 7 != 0 {
            days.append(nil)
        }

        var weeks: [[Date]] = []
        for i in stride(from: 0, to: days.count, by: 7) {
            weeks.append(days[i..<i+7].map { $0 ?? Date.distantPast })
        }
        return weeks
    }

    private var logMap: [Date: DayLog] {
        var m: [Date: DayLog] = [:]
        for l in logs { m[l.date.startOfDay] = l }
        return m
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryRow

                    yearHeatmap

                    recentList
                }
                .padding()
            }
            .navigationTitle("History")
            .sheet(item: $selectedLog) { log in
                DayDetailView(log: log)
            }
        }
    }

    // MARK: - Summary

    private var summaryRow: some View {
        let last30 = logs.filter { $0.date >= cal.date(byAdding: .day, value: -30, to: Date())! }
        let greens = last30.filter { ScoreCalculator.overall(for: $0.itemLogs) == .green }.count
        let logged = last30.count

        return HStack(spacing: 12) {
            SummaryTile(value: "\(greens)", label: "Great days", tint: .brandGreen)
            SummaryTile(value: "\(logged)", label: "Logged", tint: .brandOrange)
            SummaryTile(value: "\(currentStreak())", label: "Current streak", tint: .brandRed, glyph: "flame.fill")
        }
    }

    private func currentStreak() -> Int {
        var streak = 0
        var d = Date().startOfDay
        while let log = logMap[d], ScoreCalculator.overall(for: log.itemLogs) != .unlogged {
            streak += 1
            d = cal.date(byAdding: .day, value: -1, to: d) ?? d
        }
        return streak
    }

    // MARK: - Heatmap

    private var yearHeatmap: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Last 12 months")
                    .font(.headline)
                Spacer()
                Legend()
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 8) {
                        weekdayLabels
                        HStack(alignment: .top, spacing: tileSpacing) {
                            ForEach(Array(grid.enumerated()), id: \.offset) { idx, week in
                                weekColumn(week, index: idx)
                            }
                        }
                        .id("end")
                    }
                    .padding(.vertical, 4)
                }
                .onAppear {
                    proxy.scrollTo("end", anchor: .trailing)
                }
            }
        }
        .card()
    }

    private var weekdayLabels: some View {
        VStack(spacing: tileSpacing) {
            ForEach(0..<7, id: \.self) { i in
                Text(weekdayLabel(for: i))
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 18, height: tileSize, alignment: .trailing)
            }
        }
    }

    private func weekdayLabel(for row: Int) -> String {
        let symbols = cal.veryShortWeekdaySymbols
        let idx = (cal.firstWeekday - 1 + row) % 7
        // Show only Mon/Wed/Fri to reduce clutter
        return [1, 3, 5].contains(row) ? symbols[idx] : ""
    }

    private func weekColumn(_ week: [Date], index: Int) -> some View {
        VStack(spacing: tileSpacing) {
            ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                tile(for: day)
            }
        }
    }

    @ViewBuilder
    private func tile(for day: Date) -> some View {
        if day == Date.distantPast {
            Color.clear.frame(width: tileSize, height: tileSize)
        } else {
            let log = logMap[day]
            let status: ItemStatus = log.map { ScoreCalculator.overall(for: $0.itemLogs) } ?? .unlogged
            let isFuture = day > Date()

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(status == .unlogged ? Color.brandMuted.opacity(0.5) : status.color)
                .frame(width: tileSize, height: tileSize)
                .opacity(isFuture ? 0.3 : 1)
                .onTapGesture {
                    if let log {
                        Haptics.soft()
                        selectedLog = log
                    }
                }
        }
    }

    // MARK: - Recent list

    private var recentList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(logs.prefix(14), id: \.date) { log in
                    Button { selectedLog = log } label: {
                        recentRow(log)
                    }
                    .buttonStyle(.plain)
                }
                if logs.isEmpty {
                    Text("No logs yet")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
            }
        }
    }

    private func recentRow(_ log: DayLog) -> some View {
        let overall = ScoreCalculator.overall(for: log.itemLogs)
        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(overall.color)
                .frame(width: 6, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(relativeDate(log.date))
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text(log.date.prettyDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(overall.emoji)
                .font(.title2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func relativeDate(_ d: Date) -> String {
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInYesterday(d) { return "Yesterday" }
        let daysAgo = cal.dateComponents([.day], from: d, to: Date().startOfDay).day ?? 0
        if daysAgo < 7 { return "\(daysAgo) days ago" }
        return d.formatted("EEEE")
    }
}

private struct SummaryTile: View {
    let value: String
    let label: String
    let tint: Color
    var glyph: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                if let glyph {
                    Image(systemName: glyph).font(.caption).foregroundStyle(tint)
                }
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(tint.opacity(0.12))
        )
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 3) {
            Text("Less").font(.system(size: 9)).foregroundStyle(.secondary)
            ForEach([Color.brandMuted.opacity(0.5), Color.brandRed, Color.brandOrange, Color.brandGreen], id: \.self) { c in
                RoundedRectangle(cornerRadius: 2)
                    .fill(c)
                    .frame(width: 10, height: 10)
            }
            Text("More").font(.system(size: 9)).foregroundStyle(.secondary)
        }
    }
}


import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var monthAnchor: Date = Date()
    @State private var selectedLog: DayLog? = nil

    private let cal = Calendar.current

    private var logMap: [Date: DayLog] {
        var m: [Date: DayLog] = [:]
        for l in logs { m[l.date.startOfDay] = l }
        return m
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    summaryRow
                    calendarCard
                    legend
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

        return HStack(spacing: 10) {
            SummaryTile(value: "\(greens)", label: "Great days", tint: .brandGreen)
            SummaryTile(value: "\(logged)", label: "Logged", tint: .brandOrange)
            SummaryTile(value: "\(currentStreak())", label: "Streak", tint: .brandRed, glyph: "flame.fill")
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

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(spacing: 14) {
            monthHeader
            weekdayHeader
            calendarGrid
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
                Haptics.soft()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            Spacer()
            Text(monthAnchor.formatted("MMMM yyyy"))
                .font(.system(.headline, design: .rounded))
            Spacer()
            Button {
                shiftMonth(by: 1)
                Haptics.soft()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .frame(width: 32, height: 32)
            }
            .disabled(isCurrentMonth)
            .opacity(isCurrentMonth ? 0.3 : 1)
        }
    }

    private var weekdayHeader: some View {
        HStack {
            ForEach(orderedWeekdaySymbols, id: \.self) { s in
                Text(s)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = cal.veryShortWeekdaySymbols
        let firstIdx = cal.firstWeekday - 1
        return Array(symbols[firstIdx...] + symbols[..<firstIdx])
    }

    private var calendarGrid: some View {
        let days = cal.daysInMonth(for: monthAnchor)
        let offset = cal.firstWeekdayOffset(for: monthAnchor)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<offset, id: \.self) { _ in
                Color.clear.frame(height: 40)
            }
            ForEach(days, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let log = logMap[day.startOfDay]
        let status: ItemStatus = log.map { ScoreCalculator.overall(for: $0.itemLogs) } ?? .unlogged
        let isFuture = day > Date()
        let isToday = cal.isDateInToday(day)

        return Button {
            if log != nil { selectedLog = log; Haptics.soft() }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(status == .unlogged ? Color(.tertiarySystemFill) : status.color.opacity(0.85))
                if isToday {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.primary, lineWidth: 1.5)
                }
                Text(day.shortDay)
                    .font(.system(size: 13, weight: isToday ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(status == .unlogged ? .primary : .white)
            }
            .frame(height: 40)
            .opacity(isFuture ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(log == nil || isFuture)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach([ItemStatus.green, .orange, .red], id: \.self) { s in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(s.color.opacity(0.85))
                        .frame(width: 12, height: 12)
                    Text(s.label).font(.caption)
                }
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 12, height: 12)
                Text("No log").font(.caption)
            }
        }
        .foregroundStyle(.secondary)
    }

    private var isCurrentMonth: Bool {
        cal.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(by delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = d
        }
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

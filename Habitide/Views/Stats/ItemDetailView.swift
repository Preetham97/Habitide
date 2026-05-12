import SwiftUI
import SwiftData

struct ItemDetailView: View {
    let itemID: UUID
    let name: String
    let emoji: String

    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var monthAnchor: Date = Date()

    private let cal = Calendar.current

    private var summaries: [ItemSummary] {
        StatsEngine.itemSummaries(logs: logs)
    }
    private var summary: ItemSummary? { summaries.first { $0.id == itemID } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                statsGrid
                weekdayBreakdown
                calendarCard
            }
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 14) {
            Text(emoji)
                .font(.system(size: 38))
                .frame(width: 64, height: 64)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(.secondarySystemBackground))
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                if let s = summary {
                    Text("\(Int(s.greenPct * 100))% great over last 30 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: Stats grid

    private var statsGrid: some View {
        let s = summary
        return LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            StatTile(
                value: s.map { "\($0.currentStreak)" } ?? "—",
                label: "Current streak",
                tint: .brandOrange,
                glyph: "flame.fill"
            )
            StatTile(
                value: s.map { "\($0.longestStreak)" } ?? "—",
                label: "Longest streak",
                tint: .brandGreen,
                glyph: "trophy.fill"
            )
            StatTile(
                value: s.map { "\($0.totalLogged)" } ?? "—",
                label: "Days logged",
                tint: .primary,
                glyph: "checkmark.circle.fill"
            )
            StatTile(
                value: deltaText,
                label: "vs previous 30d",
                tint: deltaTint,
                glyph: deltaGlyph
            )
        }
    }

    private var deltaText: String {
        guard let d = summary?.deltaPct else { return "—" }
        let sign = d > 0 ? "+" : ""
        return "\(sign)\(Int(d * 100))%"
    }
    private var deltaTint: Color {
        guard let d = summary?.deltaPct else { return .primary }
        return d >= 0 ? .brandGreen : .brandRed
    }
    private var deltaGlyph: String {
        guard let d = summary?.deltaPct else { return "minus" }
        return d >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    // MARK: Weekday breakdown

    private var weekdayBreakdown: some View {
        let data = StatsEngine.itemGreenPctByWeekday(itemID: itemID, logs: logs)
        return VStack(alignment: .leading, spacing: 10) {
            Text("By weekday")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
            if data.isEmpty {
                Text("Not enough data yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                let ordered = (0..<7).map { ((cal.firstWeekday - 1 + $0) % 7) + 1 }
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(ordered, id: \.self) { wd in
                        let pct = data[wd]
                        VStack(spacing: 6) {
                            Text(pct.map { "\(Int($0 * 100))%" } ?? "—")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(pct == nil ? Color.secondary : tint(pct ?? 0))
                            GeometryReader { geo in
                                VStack {
                                    Spacer(minLength: 0)
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(pct.map(tint) ?? Color.brandMuted)
                                        .frame(height: geo.size.height * max(CGFloat(pct ?? 0), 0.05))
                                }
                            }
                            .frame(height: 70)
                            Text(StatsEngine.weekdayShort(wd))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func tint(_ pct: Double) -> Color {
        if pct >= 0.6 { return .brandGreen }
        if pct >= 0.3 { return .brandOrange }
        return .brandRed
    }

    // MARK: Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button { shiftMonth(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 30, height: 30)
                }
                Spacer()
                Text(monthAnchor.formatted("MMMM yyyy"))
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Spacer()
                Button { shiftMonth(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 30, height: 30)
                }
                .disabled(isCurrentMonth)
                .opacity(isCurrentMonth ? 0.3 : 1)
            }

            HStack {
                ForEach(orderedWeekdaySymbols, id: \.self) { s in
                    Text(s)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let days = cal.daysInMonth(for: monthAnchor)
            let offset = cal.firstWeekdayOffset(for: monthAnchor)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<offset, id: \.self) { _ in Color.clear.frame(height: 34) }
                ForEach(days, id: \.self) { day in
                    let status = statusForDay(day)
                    let isToday = cal.isDateInToday(day)
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(status == .unlogged ? Color(.tertiarySystemFill) : status.color)
                        if isToday {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(.primary, lineWidth: 1.5)
                        }
                        Text(day.shortDay)
                            .font(.system(size: 11, weight: isToday ? .bold : .semibold, design: .rounded))
                            .foregroundColor(status == .unlogged ? .primary : .white)
                    }
                    .frame(height: 34)
                    .opacity(day > Date() ? 0.3 : 1)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func statusForDay(_ day: Date) -> ItemStatus {
        let dayStart = day.startOfDay
        guard let log = logs.first(where: { cal.isDate($0.date, inSameDayAs: dayStart) }) else { return .unlogged }
        return log.itemLogs.first(where: { $0.itemID == itemID })?.status ?? .unlogged
    }

    private var isCurrentMonth: Bool {
        cal.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = d
        }
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = cal.veryShortWeekdaySymbols
        let firstIdx = cal.firstWeekday - 1
        return Array(symbols[firstIdx...] + symbols[..<firstIdx])
    }
}

private struct StatTile: View {
    let value: String
    let label: String
    let tint: Color
    let glyph: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: glyph).font(.caption).foregroundStyle(tint)
                Text(value)
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .foregroundStyle(tint)
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

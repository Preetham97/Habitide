import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var window: Window = .thirty

    enum Window: Int, CaseIterable, Identifiable {
        case seven = 7, thirty = 30, ninety = 90
        var id: Int { rawValue }
        var label: String { "\(rawValue)d" }
    }

    private var filteredLogs: [DayLog] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -window.rawValue, to: Date().startOfDay) ?? Date()
        return logs.filter { $0.date >= cutoff }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    windowPicker

                    heroCard

                    sparklineCard

                    perItemCard
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    private var windowPicker: some View {
        HStack(spacing: 8) {
            ForEach(Window.allCases) { w in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        window = w
                    }
                    Haptics.soft()
                } label: {
                    Text("Last \(w.label)")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(window == w ? Color.brandGreen : Color(.secondarySystemBackground))
                        )
                        .foregroundStyle(window == w ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        let entries = filteredLogs
            .map { ScoreCalculator.overall(for: $0.itemLogs) }
            .filter { $0 != .unlogged }
        let counts = countsByStatus(entries: entries)
        let total = max(entries.count, 1)
        let greenPct = Int((Double(counts[.green] ?? 0) / Double(total)) * 100)

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(greenPct)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("%")
                    .font(.system(.title2, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text("of logged days were great")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            stackedDistribution(counts: counts, total: total)

            HStack(spacing: 14) {
                ForEach([ItemStatus.green, .orange, .red], id: \.self) { s in
                    HStack(spacing: 6) {
                        Circle().fill(s.color).frame(width: 8, height: 8)
                        Text("\(counts[s] ?? 0)")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        Text(s.label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .card()
    }

    private func stackedDistribution(counts: [ItemStatus: Int], total: Int) -> some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach([ItemStatus.green, .orange, .red], id: \.self) { s in
                    let count = counts[s] ?? 0
                    if count > 0 {
                        Capsule()
                            .fill(s.color)
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(total) - 2)
                    }
                }
            }
        }
        .frame(height: 14)
    }

    // MARK: - Sparkline

    private var sparklineCard: some View {
        let entries = filteredLogs
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, status: ScoreCalculator.overall(for: $0.itemLogs)) }
            .filter { $0.status != .unlogged }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Daily score")
                .font(.headline)

            if entries.isEmpty {
                Text("No data yet").foregroundStyle(.secondary).font(.subheadline)
            } else {
                Chart(entries, id: \.date) { e in
                    BarMark(
                        x: .value("Date", e.date, unit: .day),
                        y: .value("Score", e.status.rawValue + 1)
                    )
                    .foregroundStyle(e.status.color)
                    .cornerRadius(3)
                }
                .frame(height: 130)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: .stride(by: window == .seven ? .day : .weekOfYear)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: true)
                            .font(.system(size: 9))
                    }
                }
            }
        }
        .card()
    }

    // MARK: - Per item

    struct PerItemAgg: Identifiable {
        let id: UUID
        let name: String
        let emoji: String
        let green: Int
        let orange: Int
        let red: Int
        let streak: Int
        var greenPct: Double {
            let total = green + orange + red
            guard total > 0 else { return 0 }
            return Double(green) / Double(total)
        }
    }

    private var perItemCard: some View {
        let perItem = aggregatePerItem().sorted { $0.greenPct > $1.greenPct }
        return VStack(alignment: .leading, spacing: 14) {
            Text("Items")
                .font(.headline)
            if perItem.isEmpty {
                Text("No data yet").foregroundStyle(.secondary).font(.subheadline)
            } else {
                ForEach(perItem) { row in
                    PerItemRow(row: row)
                }
            }
        }
        .card()
    }

    private func countsByStatus(entries: [ItemStatus]) -> [ItemStatus: Int] {
        var d: [ItemStatus: Int] = [:]
        for e in entries { d[e, default: 0] += 1 }
        return d
    }

    private func aggregatePerItem() -> [PerItemAgg] {
        var byID: [UUID: (name: String, emoji: String, sort: Int, statuses: [(Date, ItemStatus)])] = [:]
        for log in filteredLogs {
            for il in log.itemLogs where il.status != .unlogged {
                var entry = byID[il.itemID] ?? (il.itemName, il.itemEmoji, il.sortOrder, [])
                entry.statuses.append((log.date, il.status))
                byID[il.itemID] = entry
            }
        }
        return byID.map { (id, v) -> PerItemAgg in
            let sorted = v.statuses.sorted { $0.0 > $1.0 }
            var streak = 0
            for (_, s) in sorted {
                if s == .green { streak += 1 } else { break }
            }
            let g = v.statuses.filter { $0.1 == .green }.count
            let o = v.statuses.filter { $0.1 == .orange }.count
            let r = v.statuses.filter { $0.1 == .red }.count
            return PerItemAgg(id: id, name: v.name, emoji: v.emoji, green: g, orange: o, red: r, streak: streak)
        }
    }
}

private struct PerItemRow: View {
    let row: StatsView.PerItemAgg

    var body: some View {
        let total = max(row.green + row.orange + row.red, 1)
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(row.emoji).font(.title3)
                Text(row.name)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
                if row.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.caption2)
                        Text("\(row.streak)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.brandOrange))
                }
                Text("\(Int(row.greenPct * 100))%")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Color.brandGreen)
            }
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.brandGreen)
                        .frame(width: geo.size.width * CGFloat(row.green) / CGFloat(total))
                    Rectangle().fill(Color.brandOrange)
                        .frame(width: geo.size.width * CGFloat(row.orange) / CGFloat(total))
                    Rectangle().fill(Color.brandRed)
                        .frame(width: geo.size.width * CGFloat(row.red) / CGFloat(total))
                }
                .clipShape(Capsule())
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

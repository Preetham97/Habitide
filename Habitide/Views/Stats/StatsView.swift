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
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Window", selection: $window) {
                        ForEach(Window.allCases) { w in
                            Text("Last \(w.label)").tag(w)
                        }
                    }
                    .pickerStyle(.segmented)

                    overallTrendCard
                    perItemCard
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    private var overallTrendCard: some View {
        let entries = filteredLogs
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, status: ScoreCalculator.overall(for: $0.itemLogs)) }
            .filter { $0.status != .unlogged }

        return VStack(alignment: .leading, spacing: 10) {
            Text("Overall trend").font(.headline)

            if entries.isEmpty {
                Text("No data yet").foregroundStyle(.secondary).font(.subheadline)
            } else {
                Chart(entries, id: \.date) { e in
                    BarMark(
                        x: .value("Date", e.date, unit: .day),
                        y: .value("Score", e.status.rawValue + 1)
                    )
                    .foregroundStyle(e.status.color)
                }
                .frame(height: 160)
                .chartYAxis(.hidden)
            }

            let counts = countsByStatus(entries: entries.map { $0.status })
            HStack(spacing: 16) {
                ForEach([ItemStatus.green, .orange, .red], id: \.self) { s in
                    VStack(spacing: 2) {
                        Text("\(counts[s] ?? 0)").font(.title3.bold())
                        Text(s.label).font(.caption).foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(s.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var perItemCard: some View {
        let perItem = aggregatePerItem()
        return VStack(alignment: .leading, spacing: 12) {
            Text("Per item").font(.headline)
            if perItem.isEmpty {
                Text("No data yet").foregroundStyle(.secondary).font(.subheadline)
            } else {
                ForEach(perItem, id: \.id) { row in
                    PerItemRow(row: row)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func countsByStatus(entries: [ItemStatus]) -> [ItemStatus: Int] {
        var d: [ItemStatus: Int] = [:]
        for e in entries { d[e, default: 0] += 1 }
        return d
    }

    struct PerItemAgg: Identifiable {
        let id: UUID
        let name: String
        let emoji: String
        let green: Int
        let orange: Int
        let red: Int
        let streak: Int
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
        .sorted { lhs, rhs in lhs.name < rhs.name }
    }
}

private struct PerItemRow: View {
    let row: StatsView.PerItemAgg

    var body: some View {
        let total = max(row.green + row.orange + row.red, 1)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(row.emoji)
                Text(row.name).font(.subheadline.bold())
                Spacer()
                if row.streak > 0 {
                    Label("\(row.streak)", systemImage: "flame.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }
            GeometryReader { geo in
                HStack(spacing: 0) {
                    Rectangle().fill(Color.green)
                        .frame(width: geo.size.width * CGFloat(row.green) / CGFloat(total))
                    Rectangle().fill(Color.orange)
                        .frame(width: geo.size.width * CGFloat(row.orange) / CGFloat(total))
                    Rectangle().fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(row.red) / CGFloat(total))
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)
            HStack {
                Text("🟩 \(row.green)").font(.caption)
                Text("🟧 \(row.orange)").font(.caption)
                Text("🟥 \(row.red)").font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

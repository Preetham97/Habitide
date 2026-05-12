import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]

    private var headlines: [Headline] { StatsEngine.headlines(logs: logs) }
    private var summaries: [ItemSummary] { StatsEngine.itemSummaries(logs: logs) }

    private var hasEnoughData: Bool {
        logs.filter { ScoreCalculator.overall(for: $0.itemLogs) != .unlogged }.count >= 3
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headlineSection
                    if hasEnoughData {
                        patternsSection
                        itemsSection
                    } else {
                        coldStartCopy
                    }
                }
                .padding()
            }
            .navigationTitle("Stats")
        }
    }

    // MARK: Layer 1 — Headlines

    private var headlineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Highlights")
            VStack(spacing: 8) {
                ForEach(headlines) { h in
                    HeadlineCard(headline: h)
                }
            }
        }
    }

    // MARK: Layer 2 — Patterns

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Patterns")

            VStack(alignment: .leading, spacing: 10) {
                Text("By weekday")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                WeekdayStrip(data: StatsEngine.greenPctByWeekday(logs: logs))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )

            VStack(alignment: .leading, spacing: 10) {
                Text("Last 12 weeks")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                TrendChart(buckets: StatsEngine.weeklyBuckets(logs: logs, weeks: 12))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
    }

    // MARK: Layer 3 — Items

    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Items")
            if summaries.isEmpty {
                Text("No item data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            VStack(spacing: 8) {
                ForEach(summaries) { s in
                    NavigationLink {
                        ItemDetailView(itemID: s.id, name: s.name, emoji: s.emoji)
                    } label: {
                        ItemSummaryCard(summary: s)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: Bits

    private var coldStartCopy: some View {
        Text("Once you've logged a few more days, patterns and per-item trends will appear here.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }

    private func sectionTitle(_ s: String) -> some View {
        Text(s)
            .font(.system(.title3, design: .rounded).weight(.bold))
    }
}

// MARK: - Headline card

private struct HeadlineCard: View {
    let headline: Headline

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(headline.tint.opacity(0.18))
                Image(systemName: headline.icon)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(headline.tint)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(headline.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                Text(headline.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Weekday strip

private struct WeekdayStrip: View {
    let data: [Int: (pct: Double, count: Int)]
    private let cal = Calendar.current

    private var ordered: [Int] {
        let first = cal.firstWeekday
        return (0..<7).map { ((first - 1 + $0) % 7) + 1 }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(ordered, id: \.self) { wd in
                let entry = data[wd]
                VStack(spacing: 6) {
                    Text(entry.map { "\(Int($0.pct * 100))%" } ?? "—")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(entry == nil ? Color.secondary : tint(entry!.pct))
                    GeometryReader { geo in
                        VStack {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(entry.map { tint($0.pct) } ?? Color.brandMuted)
                                .frame(height: geo.size.height * max(CGFloat(entry?.pct ?? 0), 0.05))
                                .animation(.spring(response: 0.4, dampingFraction: 0.85), value: entry?.pct)
                        }
                    }
                    .frame(height: 80)
                    Text(StatsEngine.weekdayShort(wd))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func tint(_ pct: Double) -> Color {
        if pct >= 0.6 { return .brandGreen }
        if pct >= 0.3 { return .brandOrange }
        return .brandRed
    }
}

// MARK: - Trend chart

private struct TrendChart: View {
    let buckets: [WeekBucket]

    var body: some View {
        if buckets.filter({ $0.total > 0 }).count < 2 {
            Text("Not enough weeks yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 16)
        } else {
            Chart(buckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.startDate, unit: .weekOfYear),
                    y: .value("Pct", bucket.pct * 100)
                )
                .foregroundStyle(barColor(bucket.pct))
                .cornerRadius(4)
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 50, 100]) { v in
                    AxisGridLine()
                    AxisValueLabel {
                        if let n = v.as(Int.self) { Text("\(n)%").font(.system(size: 9)) }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
                        .font(.system(size: 9))
                }
            }
            .frame(height: 140)
        }
    }

    private func barColor(_ pct: Double) -> Color {
        if pct >= 0.6 { return .brandGreen }
        if pct >= 0.3 { return .brandOrange }
        return .brandRed
    }
}

// MARK: - Item summary card

private struct ItemSummaryCard: View {
    let summary: ItemSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(summary.emoji).font(.system(size: 22))
                Text(summary.name)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(.primary)
                Spacer()
                if summary.currentStreak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill").font(.caption2)
                        Text("\(summary.currentStreak)")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.brandOrange))
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }

            // Mini 30-day strip
            HStack(spacing: 2) {
                ForEach(Array(summary.recentStatuses.enumerated()), id: \.offset) { _, status in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(status == .unlogged ? Color.brandMuted.opacity(0.5) : status.color)
                        .frame(height: 16)
                }
            }

            HStack(spacing: 12) {
                Text("\(Int(summary.greenPct * 100))% great")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                if let delta = summary.deltaPct, abs(delta) >= 0.05 {
                    HStack(spacing: 2) {
                        Image(systemName: delta > 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9, weight: .heavy))
                        Text("\(Int(abs(delta * 100)))%")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(delta > 0 ? Color.brandGreen : Color.brandRed)
                }
                Spacer()
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

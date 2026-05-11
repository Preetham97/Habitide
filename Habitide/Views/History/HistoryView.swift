import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DayLog.date, order: .reverse) private var logs: [DayLog]
    @State private var monthAnchor: Date = Date()
    @State private var selectedLog: DayLog? = nil

    private let weekdaySymbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    monthHeader

                    HStack {
                        ForEach(weekdaySymbols, id: \.self) { s in
                            Text(s)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    calendarGrid

                    Legend()
                        .padding(.top, 8)
                }
                .padding()
            }
            .navigationTitle("History")
            .sheet(item: $selectedLog) { log in
                DayDetailView(log: log)
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                shiftMonth(by: -1)
            } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthAnchor.formatted("MMMM yyyy"))
                .font(.headline)
            Spacer()
            Button {
                shiftMonth(by: 1)
            } label: { Image(systemName: "chevron.right") }
                .disabled(isCurrentMonth)
        }
    }

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        return cal.isDate(monthAnchor, equalTo: Date(), toGranularity: .month)
    }

    private func shiftMonth(by delta: Int) {
        if let d = Calendar.current.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = d
        }
    }

    private var calendarGrid: some View {
        let cal = Calendar.current
        let days = cal.daysInMonth(for: monthAnchor)
        let offset = cal.firstWeekdayOffset(for: monthAnchor)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(0..<offset, id: \.self) { _ in
                Color.clear.frame(height: 44)
            }
            ForEach(days, id: \.self) { day in
                dayCell(for: day)
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let log = logs.first { Calendar.current.isDate($0.date, inSameDayAs: day) }
        let overall: ItemStatus = log.map { ScoreCalculator.overall(for: $0.itemLogs) } ?? .unlogged
        let isFuture = day > Date()

        return Button {
            if log != nil { selectedLog = log }
        } label: {
            VStack(spacing: 2) {
                Text(day.shortDay)
                    .font(.caption)
                    .foregroundStyle(isFuture ? .secondary : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(overall == .unlogged ? Color.gray.opacity(0.12) : overall.color.opacity(0.7))
            )
            .opacity(isFuture ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(log == nil || isFuture)
    }
}

private struct Legend: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach([ItemStatus.green, .orange, .red], id: \.self) { s in
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(s.color.opacity(0.7))
                        .frame(width: 14, height: 14)
                    Text(s.label).font(.caption)
                }
            }
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: 14, height: 14)
                Text("No log").font(.caption)
            }
        }
    }
}

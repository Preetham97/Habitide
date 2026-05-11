import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var shareItem: ShareImageItem? = nil

    private var routine: Routine? { routines.first(where: { $0.isActive }) ?? routines.first }

    private var todayLog: DayLog? {
        let today = Date().startOfDay
        return allLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let routine, let log = todayLog ?? ensuredTodayLog(for: routine) {
                    content(routine: routine, log: log)
                } else {
                    ContentUnavailableView("No routine yet", systemImage: "list.bullet")
                }
            }
            .background(backgroundGradient.ignoresSafeArea())
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        prepareShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(todayLog == nil)
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.image])
            }
        }
    }

    private var backgroundGradient: LinearGradient {
        let color = todayLog.map { ScoreCalculator.overall(for: $0.itemLogs) }?.color ?? .brandMuted
        return LinearGradient(
            colors: [color.opacity(0.18), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }

    @ViewBuilder
    private func content(routine: Routine, log: DayLog) -> some View {
        let sortedLogs = log.itemLogs.sorted { $0.sortOrder < $1.sortOrder }

        ScrollView {
            VStack(spacing: 18) {
                heroCard(routine: routine, log: log)

                VStack(spacing: 10) {
                    ForEach(sortedLogs, id: \.itemID) { itemLog in
                        ItemCard(log: itemLog)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
    }

    private func heroCard(routine: Routine, log: DayLog) -> some View {
        VStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(Date().formatted("EEEE").uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .tracking(1.4)
                Text(Date().formatted("MMMM d"))
                    .font(.system(.title, design: .rounded).weight(.bold))
            }

            OverallRing(logs: log.itemLogs, size: 170)
                .padding(.vertical, 4)

            let loggedCount = log.itemLogs.filter { $0.status != .unlogged }.count
            Text("\(loggedCount) of \(log.itemLogs.count) logged")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal)
    }

    private func ensuredTodayLog(for routine: Routine) -> DayLog? {
        let today = Date().startOfDay
        if let existing = allLogs.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return existing
        }
        let log = DayLog(date: today, routineName: routine.name)
        for item in routine.sortedItems {
            let itemLog = ItemLog(item: item, status: .unlogged)
            itemLog.dayLog = log
            log.itemLogs.append(itemLog)
            context.insert(itemLog)
        }
        context.insert(log)
        try? context.save()
        return log
    }

    private func prepareShare() {
        guard let log = todayLog, let routine else { return }
        let overall = ScoreCalculator.overall(for: log.itemLogs)
        let card = ShareCardView(
            date: log.date,
            routineName: routine.name,
            logs: log.itemLogs,
            overall: overall
        )
        if let img = ShareImageRenderer.render(card) {
            shareItem = ShareImageItem(image: img)
        }
    }
}

private struct ItemCard: View {
    @Bindable var log: ItemLog

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(log.status.color.opacity(log.status == .unlogged ? 0.10 : 0.18))
                Text(log.itemEmoji)
                    .font(.system(size: 26))
            }
            .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.itemName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                Text(log.status.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            StatusPicker(status: Binding(
                get: { log.status },
                set: { log.status = $0 }
            ))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct ShareImageItem: Identifiable {
    let id = UUID()
    let image: UIImage
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

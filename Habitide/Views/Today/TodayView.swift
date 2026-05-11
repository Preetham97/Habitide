import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var shareImage: UIImage? = nil
    @State private var showingShare = false

    private var routine: Routine? { routines.first(where: { $0.isActive }) ?? routines.first }

    private var todayLog: DayLog? {
        let today = Date().startOfDay
        return allLogs.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let routine, let log = todayLog ?? ensuredTodayLog(for: routine) {
                    contentView(routine: routine, log: log)
                } else {
                    ContentUnavailableView("No routine yet", systemImage: "list.bullet")
                }
            }
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
            .sheet(isPresented: $showingShare) {
                if let img = shareImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }

    @ViewBuilder
    private func contentView(routine: Routine, log: DayLog) -> some View {
        let sortedLogs = log.itemLogs.sorted { $0.sortOrder < $1.sortOrder }
        let overall = ScoreCalculator.overall(for: log.itemLogs)

        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text(Date().prettyDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(routine.name)
                        .font(.title2.bold())
                }
                .padding(.top, 8)

                VStack(spacing: 0) {
                    ForEach(sortedLogs, id: \.itemID) { itemLog in
                        ItemRow(log: itemLog)
                        if itemLog.itemID != sortedLogs.last?.itemID {
                            Divider().padding(.leading)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)

                OverallCard(overall: overall)
                    .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
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
            shareImage = img
            showingShare = true
        }
    }
}

private struct ItemRow: View {
    @Bindable var log: ItemLog

    var body: some View {
        HStack(spacing: 12) {
            Text(log.itemEmoji).font(.title2)
            Text(log.itemName).font(.body)
            Spacer()
            StatusPicker(status: Binding(
                get: { log.status },
                set: { log.status = $0 }
            ))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

private struct OverallCard: View {
    let overall: ItemStatus

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Overall")
                    .font(.headline)
                Text(overall.label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(overall.emoji)
                .font(.system(size: 44))
        }
        .padding()
        .background(overall.color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

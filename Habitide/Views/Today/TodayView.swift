import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @Query(sort: \DayLog.date, order: .reverse) private var allLogs: [DayLog]

    @State private var shareItem: ShareImageItem? = nil
    @State private var creatingRoutine = false

    private var routine: Routine? { Routine.forDate(Date(), in: routines) }

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
                    emptyState
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
            .sheet(isPresented: $creatingRoutine) {
                RoutineSetupView()
            }
        }
    }

    @ViewBuilder
    private var emptyState: some View {
        let isFirstLaunch = routines.isEmpty
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: isFirstLaunch ? "sparkles" : "calendar.badge.exclamationmark")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 6) {
                Text(isFirstLaunch ? "Welcome to Habitide" : "No routine for today")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                Text(isFirstLaunch
                     ? "Create a routine to start tracking your day."
                     : "Add a routine that covers \(Date().formatted("EEEE")) to log items today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                Haptics.soft()
                creatingRoutine = true
            } label: {
                Label("Create routine", systemImage: "plus.circle.fill")
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.brandGreen))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
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
            VStack(spacing: 12) {
                heroCard(routine: routine, log: log)

                VStack(spacing: 6) {
                    ForEach(sortedLogs, id: \.itemID) { itemLog in
                        ItemCard(log: itemLog)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 16)
        }
    }

    private func heroCard(routine: Routine, log: DayLog) -> some View {
        HStack(spacing: 14) {
            OverallRing(logs: log.itemLogs, size: 92)

            VStack(alignment: .leading, spacing: 2) {
                Text(Date().formatted("EEEE").uppercased())
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(1.3)
                Text(Date().formatted("MMMM d, yyyy"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(routine.name)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal)
        .padding(.top, 4)
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
        HStack(spacing: 10) {
            Text(log.itemEmoji)
                .font(.system(size: 22))
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(log.status.color.opacity(log.status == .unlogged ? 0.10 : 0.18))
                )

            Text(log.itemName)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))

            Spacer(minLength: 0)

            StatusPicker(status: Binding(
                get: { log.status },
                set: { log.status = $0 }
            ), compact: true)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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

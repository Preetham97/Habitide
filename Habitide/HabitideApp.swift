import SwiftUI
import SwiftData

@main
struct HabitideApp: App {
    let container: ModelContainer = {
        let schema = Schema([Routine.self, RoutineItem.self, DayLog.self, ItemLog.self])
        do {
            return try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @State private var showingSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()

                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                deduplicateRoutineDays()
                await NotificationManager.reschedule()
            }
            .task {
                try? await Task.sleep(nanoseconds: 1_400_000_000) // 1.4s
                withAnimation(.easeOut(duration: 0.35)) {
                    showingSplash = false
                }
            }
        }
        .modelContainer(container)
    }

    /// Enforce the invariant 'each weekday belongs to exactly one routine.'
    /// Earlier-created routines keep their days; later routines lose any overlap.
    @MainActor
    private func deduplicateRoutineDays() {
        let ctx = container.mainContext
        let descriptor = FetchDescriptor<Routine>(sortBy: [SortDescriptor(\.createdAt)])
        guard let routines = try? ctx.fetch(descriptor) else { return }

        var covered: Int = 0
        var changed = false
        for routine in routines {
            let overlap = routine.weekdayMask & covered
            if overlap != 0 {
                routine.weekdayMask &= ~covered
                changed = true
            }
            covered |= routine.weekdayMask
        }
        if changed { try? ctx.save() }
    }
}

import SwiftUI
import SwiftData

@main
struct HabitideApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await NotificationManager.reschedule()
                }
        }
        .modelContainer(for: [Routine.self, RoutineItem.self, DayLog.self, ItemLog.self])
    }
}

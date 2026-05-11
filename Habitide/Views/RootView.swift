import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var routines: [Routine]

    var body: some View {
        Group {
            if routines.isEmpty {
                RoutineSetupView()
            } else {
                TabView {
                    TodayView()
                        .tabItem { Label("Today", systemImage: "checkmark.circle") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "calendar") }
                    StatsView()
                        .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape") }
                }
            }
        }
    }
}

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
                        .tabItem { Label("Today", systemImage: "checkmark.circle.fill") }
                    HistoryView()
                        .tabItem { Label("History", systemImage: "square.grid.3x3.fill") }
                    StatsView()
                        .tabItem { Label("Stats", systemImage: "chart.bar.xaxis") }
                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                }
            }
        }
        .fontDesign(.rounded)
        .tint(.brandGreen)
    }
}

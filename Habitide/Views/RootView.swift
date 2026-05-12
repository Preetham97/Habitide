import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var routines: [Routine]
    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    private var appearance: AppearanceMode {
        AppearanceMode(rawValue: appearanceModeRaw) ?? .system
    }

    var body: some View {
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
        .fontDesign(.rounded)
        .tint(.primary)
        .preferredColorScheme(appearance.colorScheme)
    }
}

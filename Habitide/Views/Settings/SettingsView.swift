import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @State private var showingEditor = false

    private var routine: Routine? { routines.first(where: { $0.isActive }) ?? routines.first }

    var body: some View {
        NavigationStack {
            Form {
                if let routine {
                    Section("Routine") {
                        HStack {
                            Text(routine.name)
                            Spacer()
                            Text("\(routine.items.count) items")
                                .foregroundStyle(.secondary)
                        }
                        Button("Edit routine") { showingEditor = true }
                    }
                }
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingEditor) {
                if let routine {
                    RoutineSetupView(existingRoutine: routine)
                }
            }
        }
    }
}

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var routines: [Routine]
    @State private var showingEditor = false

    @State private var reminderEnabled: Bool = NotificationManager.isEnabled
    @State private var reminderDate: Date = SettingsView.dateFromComponents(NotificationManager.reminderTime)
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

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

                Section {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, newValue in
                            Task { await setEnabled(newValue) }
                        }
                    if reminderEnabled {
                        DatePicker("Time", selection: $reminderDate, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderDate) { _, newValue in
                                Task { await setTime(newValue) }
                            }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text(reminderFooter)
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingEditor) {
                if let routine {
                    RoutineSetupView(existingRoutine: routine)
                }
            }
            .task { authStatus = await NotificationManager.authorizationStatus() }
        }
    }

    private var reminderFooter: String {
        switch authStatus {
        case .denied:
            return "Notifications are off for Habitide. Enable them in iOS Settings to receive reminders."
        case .authorized, .provisional, .ephemeral:
            return reminderEnabled
                ? "You'll get a nudge at this time each day."
                : "Enable to get a daily reminder to log your items."
        case .notDetermined:
            return "We'll ask for notification permission when you enable this."
        @unknown default:
            return ""
        }
    }

    private func setEnabled(_ enabled: Bool) async {
        NotificationManager.isEnabled = enabled
        if enabled {
            let status = await NotificationManager.authorizationStatus()
            if status == .notDetermined {
                _ = await NotificationManager.requestAuthorization()
            }
            authStatus = await NotificationManager.authorizationStatus()
        }
        await NotificationManager.reschedule()
    }

    private func setTime(_ date: Date) async {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        NotificationManager.reminderTime = comps
        await NotificationManager.reschedule()
    }

    private static func dateFromComponents(_ comps: DateComponents) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = comps.hour
        c.minute = comps.minute
        return Calendar.current.date(from: c) ?? Date()
    }
}

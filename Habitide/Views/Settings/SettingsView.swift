import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Routine.createdAt) private var routines: [Routine]

    @State private var editingRoutine: Routine? = nil
    @State private var creatingRoutine = false

    @State private var reminderEnabled: Bool = NotificationManager.isEnabled
    @State private var reminderDate: Date = SettingsView.dateFromComponents(NotificationManager.reminderTime)
    @State private var authStatus: UNAuthorizationStatus = .notDetermined

    @AppStorage("appearanceMode") private var appearanceModeRaw: String = AppearanceMode.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(routines) { routine in
                        Button {
                            editingRoutine = routine
                        } label: {
                            routineRow(routine)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteRoutines)

                    Button {
                        creatingRoutine = true
                    } label: {
                        Label("New routine", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Routines")
                } footer: {
                    Text(coverageFooter)
                        .font(.caption)
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearanceModeRaw) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Label(mode.label, systemImage: mode.glyph)
                                .tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    Toggle("Daily reminder", isOn: $reminderEnabled)
                        .tint(.brandGreen)
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
            .sheet(item: $editingRoutine) { r in
                RoutineSetupView(existingRoutine: r)
            }
            .sheet(isPresented: $creatingRoutine) {
                RoutineSetupView()
            }
            .task { authStatus = await NotificationManager.authorizationStatus() }
        }
    }

    private func routineRow(_ routine: Routine) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(routine.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(routine.items.count) items • \(routine.weekdaysLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private var coverageFooter: String {
        let covered = routines.reduce(0) { $0 | $1.weekdayMask }
        let uncovered = (~covered) & 0b1111111
        if uncovered == 0 { return "All days are covered." }
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let names = (0..<7).compactMap { (uncovered & (1 << $0)) != 0 ? symbols[$0] : nil }
        return "No routine for: \(names.joined(separator: ", "))"
    }

    private func deleteRoutines(_ offsets: IndexSet) {
        for i in offsets {
            context.delete(routines[i])
        }
        try? context.save()
    }

    // MARK: - Reminders

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

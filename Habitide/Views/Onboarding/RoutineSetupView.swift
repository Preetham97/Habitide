import SwiftUI
import SwiftData

struct RoutineSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existingRoutine: Routine? = nil

    @Query private var allRoutines: [Routine]
    @State private var routineName: String = "Daily Routine"
    @State private var weekdayMask: Int = 0b1111111
    @State private var drafts: [ItemDraft] = []
    @State private var editingEmojiIndex: Int? = nil
    @State private var didLoad = false

    struct ItemDraft: Identifiable, Equatable {
        /// Reuses the existing RoutineItem.id when editing, so sync logic
        /// can match drafts back to their underlying records.
        var id: UUID = UUID()
        var name: String
        var emoji: String
    }

    private let defaultEmojis = ["🎯","🌱","💪","📚","🧘","☕️","🛏️","✍️","🧠","🚶","🏋️","🍎"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine name") {
                    TextField("e.g. Daily Routine", text: $routineName)
                }

                Section {
                    WeekdayPicker(mask: $weekdayMask, lockedMask: lockedMask)
                        .padding(.vertical, 4)
                } header: {
                    Text("Active days")
                } footer: {
                    Text(daysFooter)
                        .font(.caption)
                }

                Section {
                    ForEach(Array($drafts.enumerated()), id: \.element.id) { index, $draft in
                        HStack(spacing: 12) {
                            Button {
                                editingEmojiIndex = index
                            } label: {
                                Text(draft.emoji.isEmpty ? "❓" : draft.emoji)
                                    .font(.title2)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color(.tertiarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                            TextField("Item name", text: $draft.name)
                        }
                    }
                    .onDelete { drafts.remove(atOffsets: $0) }
                    .onMove { drafts.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        drafts.append(.init(name: "", emoji: defaultEmojis.randomElement() ?? "🎯"))
                    } label: {
                        Label("Add item", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Items")
                } footer: {
                    Text("Tap Edit to reorder or remove items.")
                        .font(.caption)
                }
            }
            .navigationTitle(existingRoutine == nil ? "Create routine" : "Edit routine")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
            .onAppear(perform: loadInitial)
            .sheet(item: Binding(
                get: { editingEmojiIndex.map { EmojiEdit(index: $0) } },
                set: { editingEmojiIndex = $0?.index }
            )) { edit in
                EmojiPickerSheet(emoji: Binding(
                    get: { drafts[edit.index].emoji },
                    set: { drafts[edit.index].emoji = $0 }
                ))
            }
        }
    }

    private struct EmojiEdit: Identifiable {
        let index: Int
        var id: Int { index }
    }

    private var canSave: Bool {
        !routineName.trimmingCharacters(in: .whitespaces).isEmpty &&
        drafts.contains { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty } &&
        weekdayMask != 0
    }

    private var lockedMask: Int {
        others().reduce(0) { $0 | $1.weekdayMask }
    }

    private var daysFooter: String {
        if weekdayMask == 0 { return "Pick at least one day." }
        let locked = lockedMask & ~weekdayMask & 0b1111111
        if locked == 0 { return "" }
        return "Grayed-out days belong to another routine. Edit it first to free them up."
    }

    private func others() -> [Routine] {
        allRoutines.filter { $0 !== existingRoutine }
    }

    private func loadInitial() {
        guard !didLoad else { return }
        didLoad = true

        if let routine = existingRoutine {
            routineName = routine.name
            weekdayMask = routine.weekdayMask
            drafts = routine.sortedItems.map { ItemDraft(id: $0.id, name: $0.name, emoji: $0.emoji) }
        } else {
            // New routine: default to days not yet covered (or empty if all covered)
            let covered = allRoutines.reduce(0) { $0 | $1.weekdayMask }
            let uncovered = (~covered) & 0b1111111
            weekdayMask = uncovered != 0 ? uncovered : 0b1111111
            if drafts.isEmpty {
                drafts = [
                    .init(name: "Sleep", emoji: "😴"),
                    .init(name: "Work", emoji: "💼"),
                    .init(name: "Exercise", emoji: "🏃"),
                    .init(name: "Diet", emoji: "🥗"),
                    .init(name: "10k Steps", emoji: "👟"),
                    .init(name: "3.5L Water", emoji: "💧"),
                ]
            }
        }
    }

    private func save() {
        let valid = drafts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }

        let routine: Routine
        if let existing = existingRoutine {
            existing.name = routineName
            existing.weekdayMask = weekdayMask

            // Edit RoutineItems in-place so their UUIDs stay stable.
            let existingByID = Dictionary(uniqueKeysWithValues: existing.items.map { ($0.id, $0) })
            var keptIDs: Set<UUID> = []
            for (idx, d) in valid.enumerated() {
                if let item = existingByID[d.id] {
                    item.name = d.name
                    item.emoji = d.emoji
                    item.sortOrder = idx
                    keptIDs.insert(item.id)
                } else {
                    let new = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                    new.id = d.id
                    new.routine = existing
                    context.insert(new)
                    keptIDs.insert(new.id)
                }
            }
            for item in existing.items where !keptIDs.contains(item.id) {
                context.delete(item)
            }
            routine = existing
        } else {
            let new = Routine(name: routineName, weekdayMask: weekdayMask)
            context.insert(new)
            for (idx, d) in valid.enumerated() {
                let item = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                item.id = d.id
                item.routine = new
                context.insert(item)
            }
            routine = new
        }

        try? context.save()
        syncTodayLog(for: routine)
        try? context.save()

        Task {
            if existingRoutine == nil && allRoutines.isEmpty {
                _ = await NotificationManager.requestAuthorization()
            }
            await NotificationManager.reschedule()
        }
        dismiss()
    }

    /// Mirror item edits onto today's DayLog so reorders/adds/removes show up
    /// immediately in the Today view and share card. Past DayLogs are left
    /// frozen — they stay as the snapshot of how the routine looked that day.
    private func syncTodayLog(for routine: Routine) {
        let today = Date().startOfDay
        let weekday = Calendar.current.component(.weekday, from: today)
        guard routine.covers(weekday: weekday) else { return }

        let fetch = FetchDescriptor<DayLog>(predicate: #Predicate { $0.date == today })
        guard let log = try? context.fetch(fetch).first else { return }

        let logsByItemID = Dictionary(uniqueKeysWithValues: log.itemLogs.map { ($0.itemID, $0) })
        var keptItemIDs: Set<UUID> = []

        for item in routine.sortedItems {
            if let il = logsByItemID[item.id] {
                il.sortOrder = item.sortOrder
                il.itemName = item.name
                il.itemEmoji = item.emoji
            } else {
                let new = ItemLog(item: item, status: .unlogged)
                new.dayLog = log
                log.itemLogs.append(new)
                context.insert(new)
            }
            keptItemIDs.insert(item.id)
        }
        for il in log.itemLogs where !keptItemIDs.contains(il.itemID) {
            context.delete(il)
        }
    }
}

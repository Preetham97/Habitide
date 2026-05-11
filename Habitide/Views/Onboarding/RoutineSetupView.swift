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
        let id = UUID()
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
                    WeekdayPicker(mask: $weekdayMask)
                        .padding(.vertical, 4)
                } header: {
                    Text("Active days")
                } footer: {
                    Text(conflictFooter)
                        .font(.caption)
                }

                Section("Items") {
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

    private var conflictFooter: String {
        let conflicts = others().filter { ($0.weekdayMask & weekdayMask) != 0 }
        if weekdayMask == 0 { return "Pick at least one day." }
        if conflicts.isEmpty { return "These days are unique to this routine." }
        let names = conflicts.map(\.name).joined(separator: ", ")
        return "Will take days from: \(names)"
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
            drafts = routine.sortedItems.map { ItemDraft(name: $0.name, emoji: $0.emoji) }
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

        // Resolve day-conflicts: any other routine claiming the same day(s) loses them.
        for other in others() where (other.weekdayMask & weekdayMask) != 0 {
            other.weekdayMask &= ~weekdayMask
        }

        if let routine = existingRoutine {
            routine.name = routineName
            routine.weekdayMask = weekdayMask
            for item in routine.items { context.delete(item) }
            for (idx, d) in valid.enumerated() {
                let item = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                item.routine = routine
                context.insert(item)
            }
        } else {
            let routine = Routine(name: routineName, weekdayMask: weekdayMask)
            context.insert(routine)
            for (idx, d) in valid.enumerated() {
                let item = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                item.routine = routine
                context.insert(item)
            }
        }
        try? context.save()
        Task {
            if existingRoutine == nil && allRoutines.isEmpty {
                _ = await NotificationManager.requestAuthorization()
            }
            await NotificationManager.reschedule()
        }
        dismiss()
    }
}

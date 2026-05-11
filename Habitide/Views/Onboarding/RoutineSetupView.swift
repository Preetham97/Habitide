import SwiftUI
import SwiftData

struct RoutineSetupView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var existingRoutine: Routine? = nil

    @State private var routineName: String = "Daily Routine"
    @State private var drafts: [ItemDraft] = []
    @State private var showingEmojiFor: UUID? = nil

    struct ItemDraft: Identifiable, Equatable {
        let id = UUID()
        var name: String
        var emoji: String
    }

    private let suggestedEmojis = ["😴","💼","🏃","🥗","👟","💧","📚","🧘","☕️","💪","🛏️","✍️","🎯","🧠","🌱","🚶","🏋️","🍎","🚭","📵"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Routine name") {
                    TextField("e.g. Daily Routine", text: $routineName)
                }

                Section("Items") {
                    ForEach($drafts) { $draft in
                        HStack(spacing: 12) {
                            Menu {
                                ForEach(suggestedEmojis, id: \.self) { e in
                                    Button(e) { draft.emoji = e }
                                }
                            } label: {
                                Text(draft.emoji.isEmpty ? "❓" : draft.emoji)
                                    .font(.title2)
                                    .frame(width: 36, height: 36)
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            TextField("Item name", text: $draft.name)
                        }
                    }
                    .onDelete { drafts.remove(atOffsets: $0) }
                    .onMove { drafts.move(fromOffsets: $0, toOffset: $1) }

                    Button {
                        drafts.append(.init(name: "", emoji: suggestedEmojis.randomElement() ?? "🎯"))
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
                if existingRoutine != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { dismiss() }
                    }
                }
                ToolbarItem(placement: .bottomBar) { EditButton() }
            }
            .onAppear(perform: loadInitial)
        }
    }

    private var canSave: Bool {
        !routineName.trimmingCharacters(in: .whitespaces).isEmpty &&
        drafts.contains { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    private func loadInitial() {
        if let routine = existingRoutine {
            routineName = routine.name
            drafts = routine.sortedItems.map { ItemDraft(name: $0.name, emoji: $0.emoji) }
        } else if drafts.isEmpty {
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

    private func save() {
        let valid = drafts.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }

        if let routine = existingRoutine {
            routine.name = routineName
            for item in routine.items { context.delete(item) }
            for (idx, d) in valid.enumerated() {
                let item = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                item.routine = routine
                context.insert(item)
            }
        } else {
            let routine = Routine(name: routineName)
            context.insert(routine)
            for (idx, d) in valid.enumerated() {
                let item = RoutineItem(name: d.name, emoji: d.emoji, sortOrder: idx)
                item.routine = routine
                context.insert(item)
            }
        }
        try? context.save()
        dismiss()
    }
}

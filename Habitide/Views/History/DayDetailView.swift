import SwiftUI

struct DayDetailView: View {
    let log: DayLog
    @Environment(\.dismiss) private var dismiss
    @State private var shareItem: ShareImageItem? = nil

    var body: some View {
        NavigationStack {
            let sorted = log.itemLogs.sorted { $0.sortOrder < $1.sortOrder }
            let overall = ScoreCalculator.overall(for: log.itemLogs)

            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 10) {
                        OverallRing(logs: log.itemLogs, size: 130)
                        VStack(spacing: 2) {
                            Text(log.date.formatted("EEEE").uppercased())
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .tracking(1.2)
                            Text(log.date.formatted("MMMM d, yyyy"))
                                .font(.system(.title3, design: .rounded).weight(.bold))
                        }
                    }
                    .padding(.top)

                    VStack(spacing: 8) {
                        ForEach(sorted, id: \.itemID) { itemLog in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(itemLog.status.color.opacity(0.18))
                                    Text(itemLog.itemEmoji).font(.title3)
                                }
                                .frame(width: 44, height: 44)
                                Text(itemLog.itemName)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                Spacer()
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(itemLog.status.color)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: itemLog.status.glyph)
                                            .font(.caption.bold())
                                            .foregroundStyle(.white)
                                    )
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        prepareShare(overall: overall)
                    } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
            .sheet(item: $shareItem) { item in
                ShareSheet(items: [item.image])
            }
        }
        .fontDesign(.rounded)
    }

    private func prepareShare(overall: ItemStatus) {
        let card = ShareCardView(date: log.date, routineName: log.routineName, logs: log.itemLogs, overall: overall)
        if let img = ShareImageRenderer.render(card) {
            shareItem = ShareImageItem(image: img)
        }
    }
}

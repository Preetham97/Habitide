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

                    VStack(spacing: 6) {
                        ForEach(sorted, id: \.itemID) { itemLog in
                            HStack(spacing: 10) {
                                Text(itemLog.itemEmoji)
                                    .font(.system(size: 22))
                                    .frame(width: 36, height: 36)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(itemLog.status.color.opacity(0.18))
                                    )
                                Text(itemLog.itemName)
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                Spacer()
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(itemLog.status.color)
                                    .frame(width: 26, height: 26)
                                    .overlay(
                                        Image(systemName: itemLog.status.glyph)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
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

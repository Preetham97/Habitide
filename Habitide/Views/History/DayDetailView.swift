import SwiftUI

struct DayDetailView: View {
    let log: DayLog
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage? = nil
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            let sorted = log.itemLogs.sorted { $0.sortOrder < $1.sortOrder }
            let overall = ScoreCalculator.overall(for: log.itemLogs)

            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 4) {
                        Text(log.date.prettyDate)
                            .font(.title2.bold())
                        Text(log.routineName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)

                    VStack(spacing: 0) {
                        ForEach(sorted, id: \.itemID) { itemLog in
                            HStack {
                                Text(itemLog.itemEmoji)
                                Text(itemLog.itemName)
                                Spacer()
                                Text(itemLog.status.emoji).font(.title3)
                            }
                            .padding()
                            if itemLog.itemID != sorted.last?.itemID {
                                Divider().padding(.leading)
                            }
                        }
                    }
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    HStack {
                        Text("Overall").font(.headline)
                        Spacer()
                        Text(overall.emoji).font(.system(size: 40))
                    }
                    .padding()
                    .background(overall.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)
                }
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
            .sheet(isPresented: $showingShare) {
                if let img = shareImage {
                    ShareSheet(items: [img])
                }
            }
        }
    }

    private func prepareShare(overall: ItemStatus) {
        let card = ShareCardView(date: log.date, routineName: log.routineName, logs: log.itemLogs, overall: overall)
        if let img = ShareImageRenderer.render(card) {
            shareImage = img
            showingShare = true
        }
    }
}

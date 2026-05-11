import SwiftUI

struct ShareCardView: View {
    let date: Date
    let routineName: String
    let logs: [ItemLog]
    let overall: ItemStatus

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text(date.prettyDate)
                    .font(.title2.bold())
                Text(routineName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(logs.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.itemID) { log in
                    HStack {
                        Text(log.itemEmoji)
                        Text(log.itemName)
                            .font(.body)
                        Spacer()
                        Text(log.status.emoji)
                            .font(.title3)
                    }
                }
            }

            Divider()

            HStack {
                Text("Overall")
                    .font(.headline)
                Spacer()
                Text(overall.emoji)
                    .font(.largeTitle)
            }

            Text("— Habitide")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 360, height: 360)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(overall.color.opacity(0.4), lineWidth: 2)
        )
        .padding(8)
    }
}

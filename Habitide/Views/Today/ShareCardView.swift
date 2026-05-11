import SwiftUI

struct ShareCardView: View {
    let date: Date
    let routineName: String
    let logs: [ItemLog]
    let overall: ItemStatus

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.formatted("EEEE").uppercased())
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(1.2)
                    Text(date.formatted("MMM d"))
                        .font(.system(.title2, design: .rounded).weight(.bold))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.brandMuted, lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: overall == .unlogged ? 0 : 1)
                        .stroke(overall.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 56, height: 56)
                    Text(overall.emoji).font(.title3)
                }
            }

            VStack(spacing: 8) {
                ForEach(logs.sorted(by: { $0.sortOrder < $1.sortOrder }), id: \.itemID) { log in
                    HStack(spacing: 12) {
                        Text(log.itemEmoji).font(.title3)
                        Text(log.itemName)
                            .font(.system(.body, design: .rounded).weight(.medium))
                        Spacer()
                        RoundedRectangle(cornerRadius: 6)
                            .fill(log.status.color)
                            .frame(width: 22, height: 22)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(.tertiarySystemBackground))
                    )
                }
            }

            HStack {
                Text("Habitide")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                Spacer()
                Text(overall.label)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(overall.color)
            }
        }
        .padding(22)
        .frame(width: 380, height: 480)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(overall.color.opacity(0.35), lineWidth: 1.5)
        )
        .padding(8)
        .fontDesign(.rounded)
    }
}

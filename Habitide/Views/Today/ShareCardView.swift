import SwiftUI

struct ShareCardView: View {
    let date: Date
    let routineName: String
    let logs: [ItemLog]
    let overall: ItemStatus

    private var gradientColors: [Color] {
        switch overall {
        case .green:
            return [Color(red: 0.08, green: 0.42, blue: 0.32), Color(red: 0.04, green: 0.18, blue: 0.20)]
        case .orange:
            return [Color(red: 0.62, green: 0.36, blue: 0.10), Color(red: 0.24, green: 0.13, blue: 0.06)]
        case .red:
            return [Color(red: 0.56, green: 0.16, blue: 0.22), Color(red: 0.22, green: 0.06, blue: 0.10)]
        default:
            return [Color(red: 0.18, green: 0.18, blue: 0.22), Color(red: 0.08, green: 0.08, blue: 0.10)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .fill(overall.color.opacity(0.25))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: -130, y: -200)

            Circle()
                .fill(overall.color.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 70)
                .offset(x: 150, y: 220)

            VStack(spacing: 18) {
                header
                itemList
                footer
            }
            .padding(26)
        }
        .frame(width: 540, height: 720)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(8)
        .fontDesign(.rounded)
        .colorScheme(.dark)
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack(spacing: 16) {
            OverallRing(
                logs: logs,
                size: 110,
                trackColor: Color.white.opacity(0.08),
                unloggedSegmentColor: Color.white.opacity(0.20)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted("EEEE").uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.6))
                Text(date.formatted("MMMM d, yyyy"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(routineName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 2)
            }
            Spacer(minLength: 0)
        }
    }

    private var itemList: some View {
        let sorted = logs.sorted { $0.sortOrder < $1.sortOrder }
        return VStack(spacing: 8) {
            ForEach(sorted, id: \.itemID) { log in
                HStack(spacing: 12) {
                    Text(log.itemEmoji)
                        .font(.system(size: 22))
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(log.status == .unlogged
                                    ? Color.white.opacity(0.08)
                                    : log.status.color.opacity(0.25))
                        )
                    Text(log.itemName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer(minLength: 0)
                    if log.status == .unlogged {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    } else {
                        Image(systemName: log.status.glyph)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(log.status.color)
                            )
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
            }
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.white)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(.black)
                    )
                Text("Habitide")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Spacer()
            Text(loggedSummary)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var loggedSummary: String {
        let logged = logs.filter { $0.status != .unlogged }.count
        return "\(logged)/\(logs.count) tracked"
    }
}

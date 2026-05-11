import SwiftUI

struct ShareCardView: View {
    let date: Date
    let routineName: String
    let logs: [ItemLog]
    let overall: ItemStatus

    private var gradientColors: [Color] {
        let tint: Color
        switch overall {
        case .green:    tint = .brandGreen
        case .orange:   tint = .brandOrange
        case .red:      tint = .brandRed
        case .unlogged: tint = Color.gray
        }
        return [tint.opacity(0.22), Color.white]
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)

            // Soft tint glow
            Circle()
                .fill(overall.color.opacity(0.18))
                .frame(width: 280, height: 280)
                .blur(radius: 80)
                .offset(x: -130, y: -220)

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
        .colorScheme(.light)
        .foregroundStyle(.black)
    }

    private var header: some View {
        HStack(spacing: 16) {
            OverallRing(
                logs: logs,
                size: 110,
                trackColor: Color.black.opacity(0.06),
                unloggedSegmentColor: Color.black.opacity(0.18)
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted("EEEE").uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.black.opacity(0.5))
                Text(date.formatted("MMMM d, yyyy"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(routineName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black.opacity(0.55))
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
                                    ? Color.black.opacity(0.04)
                                    : log.status.color.opacity(0.22))
                        )
                    Text(log.itemName)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                    Spacer(minLength: 0)
                    if log.status == .unlogged {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.black.opacity(0.3))
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
                        .fill(.white.opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.black.opacity(0.04), lineWidth: 1)
                )
            }
        }
    }

    private var footer: some View {
        HStack {
            HStack(spacing: 8) {
                Image("BrandIcon")
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 26, height: 26)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                Text("Habitide")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            Spacer()
            Text(loggedSummary)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(.black.opacity(0.5))
        }
    }

    private var loggedSummary: String {
        let logged = logs.filter { $0.status != .unlogged }.count
        return "\(logged)/\(logs.count) tracked"
    }
}

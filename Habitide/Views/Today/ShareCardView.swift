import SwiftUI

struct ShareCardView: View {
    let date: Date
    let routineName: String
    let logs: [ItemLog]
    let overall: ItemStatus

    private var progress: Double {
        let logged = logs.filter { $0.status != .unlogged }
        guard !logged.isEmpty else { return 0 }
        let pts = logged.reduce(0) { $0 + $1.status.rawValue }
        return Double(pts) / Double(logged.count * 2)
    }

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

            // Decorative glow
            Circle()
                .fill(overall.color.opacity(0.25))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: -120, y: -160)

            Circle()
                .fill(overall.color.opacity(0.18))
                .frame(width: 240, height: 240)
                .blur(radius: 60)
                .offset(x: 140, y: 200)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 12)
                ringSection
                Spacer(minLength: 16)
                itemGrid
                Spacer(minLength: 12)
                footer
            }
            .padding(28)
        }
        .frame(width: 540, height: 540)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(8)
        .fontDesign(.rounded)
        .colorScheme(.dark)
        .foregroundStyle(.white)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.formatted("EEEE").uppercased())
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.6))
                Text(date.formatted("MMMM d"))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(routineName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                HStack(spacing: 4) {
                    Circle().fill(overall.color).frame(width: 8, height: 8)
                    Text(overall.label.uppercased())
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
    }

    private var ringSection: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 14)
            Circle()
                .trim(from: 0, to: max(progress, 0.001))
                .stroke(
                    LinearGradient(
                        colors: [overall.color, overall.color.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text(overall.emoji)
                .font(.system(size: 86))
        }
        .frame(width: 200, height: 200)
    }

    private var itemGrid: some View {
        let sorted = logs.sorted { $0.sortOrder < $1.sortOrder }
        let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(sorted, id: \.itemID) { log in
                HStack(spacing: 10) {
                    Text(log.itemEmoji).font(.system(size: 20))
                    Text(log.itemName)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Circle()
                        .fill(log.status.color)
                        .frame(width: 14, height: 14)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(.white.opacity(0.06), lineWidth: 1)
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

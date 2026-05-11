import SwiftUI

struct OverallRing: View {
    let logs: [ItemLog]
    let size: CGFloat

    private var progress: Double {
        let logged = logs.filter { $0.status != .unlogged }
        guard !logged.isEmpty else { return 0 }
        let pts = logged.reduce(0) { $0 + $1.status.rawValue }
        let max = logged.count * 2
        return Double(pts) / Double(max)
    }

    private var overall: ItemStatus { ScoreCalculator.overall(for: logs) }
    private var loggedFraction: Double {
        guard !logs.isEmpty else { return 0 }
        return Double(logs.filter { $0.status != .unlogged }.count) / Double(logs.count)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.brandMuted, lineWidth: size * 0.10)
            Circle()
                .trim(from: 0, to: loggedFraction)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: size * 0.10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: loggedFraction)
            VStack(spacing: 2) {
                Text(overall.emoji)
                    .font(.system(size: size * 0.32))
                Text(overall.label)
                    .font(.system(size: size * 0.10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
            }
        }
        .frame(width: size, height: size)
    }

    private var gradientColors: [Color] {
        if overall == .unlogged { return [.brandMuted, .brandMuted] }
        let base = overall.color
        return [base.opacity(0.7), base]
    }
}

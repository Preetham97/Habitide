import SwiftUI

struct OverallRing: View {
    let logs: [ItemLog]
    let size: CGFloat
    /// Optional track color override (defaults to a subtle system fill).
    var trackColor: Color? = nil
    /// Optional override for the unlogged-segment color (unused now, kept
    /// for call-site compatibility).
    var unloggedSegmentColor: Color? = nil

    private var overall: ItemStatus { ScoreCalculator.overall(for: logs) }

    private var loggedFraction: Double {
        guard !logs.isEmpty else { return 0 }
        let logged = logs.filter { $0.status != .unlogged }.count
        return Double(logged) / Double(logs.count)
    }

    var body: some View {
        let lineWidth = size * 0.11
        let track = trackColor ?? Color.brandMuted.opacity(0.4)
        let arcColor = overall == .unlogged ? Color.brandMuted : overall.color

        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: loggedFraction)
                .stroke(
                    arcColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.85), value: loggedFraction)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: arcColor)

            Image(systemName: overall.glyph)
                .font(.system(size: size * 0.34, weight: .heavy))
                .foregroundStyle(overall == .unlogged ? Color.secondary : overall.color)
        }
        .frame(width: size, height: size)
    }
}

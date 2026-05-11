import SwiftUI

struct OverallRing: View {
    let logs: [ItemLog]
    let size: CGFloat
    /// Optional track color override (defaults to a subtle system fill).
    var trackColor: Color? = nil
    /// Optional override for the unlogged-segment color.
    var unloggedSegmentColor: Color? = nil

    private var sortedLogs: [ItemLog] {
        logs.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var overall: ItemStatus { ScoreCalculator.overall(for: logs) }

    var body: some View {
        let count = max(sortedLogs.count, 1)
        let lineWidth = size * 0.11
        let gapDeg: Double = count >= 6 ? 6 : 8
        let segDeg: Double = (360.0 - gapDeg * Double(count)) / Double(count)
        let track = trackColor ?? Color.brandMuted.opacity(0.4)
        let unloggedColor = unloggedSegmentColor ?? Color.brandMuted

        ZStack {
            Circle()
                .stroke(track, lineWidth: lineWidth * 0.55)

            ForEach(Array(sortedLogs.enumerated()), id: \.element.itemID) { idx, log in
                let start = Double(idx) * (segDeg + gapDeg) + gapDeg / 2
                let end = start + segDeg
                Circle()
                    .trim(from: start / 360, to: end / 360)
                    .stroke(
                        log.status == .unlogged ? unloggedColor : log.status.color,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: log.statusRaw)
            }

            Image(systemName: overall.glyph)
                .font(.system(size: size * 0.34, weight: .heavy))
                .foregroundStyle(overall == .unlogged ? Color.secondary : overall.color)
        }
        .frame(width: size, height: size)
    }
}

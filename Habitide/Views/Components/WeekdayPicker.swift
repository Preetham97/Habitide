import SwiftUI

struct WeekdayPicker: View {
    @Binding var mask: Int
    /// Days owned by other routines — shown but disabled.
    var lockedMask: Int = 0

    private let labels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let bit = 1 << i
                let isOn = (mask & bit) != 0
                let isLocked = (lockedMask & bit) != 0 && !isOn

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        mask ^= bit
                    }
                    Haptics.light()
                } label: {
                    chipLabel(letter: labels[i], isOn: isOn, isLocked: isLocked)
                }
                .buttonStyle(.plain)
                .disabled(isLocked)
            }
        }
    }

    @ViewBuilder
    private func chipLabel(letter: String, isOn: Bool, isLocked: Bool) -> some View {
        ZStack {
            Capsule(style: .continuous)
                .fill(fillStyle(isOn: isOn, isLocked: isLocked))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isOn ? Color.white.opacity(0.18) : Color.primary.opacity(0.06),
                            lineWidth: 1
                        )
                )

            Text(letter)
                .font(.system(.subheadline, design: .rounded).weight(.heavy))
                .foregroundColor(foregroundColor(isOn: isOn, isLocked: isLocked))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .shadow(color: isOn ? Color.brandGreen.opacity(0.45) : .clear, radius: 6, y: 3)
        .scaleEffect(isOn ? 1.02 : 1.0)
    }

    private func fillStyle(isOn: Bool, isLocked: Bool) -> AnyShapeStyle {
        if isOn {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color.brandGreen,
                        Color.brandGreen.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        if isLocked {
            return AnyShapeStyle(Color(.tertiarySystemBackground).opacity(0.5))
        }
        return AnyShapeStyle(Color(.tertiarySystemBackground))
    }

    private func foregroundColor(isOn: Bool, isLocked: Bool) -> Color {
        if isOn { return .white }
        if isLocked { return .secondary.opacity(0.4) }
        return .secondary
    }
}

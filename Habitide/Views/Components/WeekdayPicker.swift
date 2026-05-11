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
                    Text(labels[i])
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(background(isOn: isOn, isLocked: isLocked))
                        .foregroundColor(foreground(isOn: isOn, isLocked: isLocked))
                }
                .buttonStyle(.plain)
                .disabled(isLocked)
            }
        }
    }

    private func background(isOn: Bool, isLocked: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isOn ? Color.brandGreen
                  : isLocked ? Color(.tertiarySystemBackground).opacity(0.5)
                  : Color(.tertiarySystemBackground))
    }

    private func foreground(isOn: Bool, isLocked: Bool) -> Color {
        if isOn { return .white }
        if isLocked { return .secondary.opacity(0.4) }
        return .primary
    }
}

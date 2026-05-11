import SwiftUI

struct WeekdayPicker: View {
    @Binding var mask: Int

    private let labels = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let isOn = (mask & (1 << i)) != 0
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        mask ^= (1 << i)
                    }
                    Haptics.light()
                } label: {
                    Text(labels[i])
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isOn ? Color.brandGreen : Color(.tertiarySystemBackground))
                        )
                        .foregroundColor(isOn ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

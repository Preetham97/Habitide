import SwiftUI

struct StatusPicker: View {
    @Binding var status: ItemStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            ForEach([ItemStatus.red, .orange, .green], id: \.self) { option in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                        status = option
                    }
                    Haptics.light()
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(status == option ? option.color : option.color.opacity(0.18))
                        Image(systemName: option.glyph)
                            .font(.system(size: compact ? 12 : 14, weight: .bold))
                            .foregroundStyle(status == option ? .white : option.color)
                    }
                    .frame(width: compact ? 32 : 38, height: compact ? 32 : 38)
                    .scaleEffect(status == option ? 1.0 : 0.92)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

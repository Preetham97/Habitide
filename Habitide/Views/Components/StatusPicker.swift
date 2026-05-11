import SwiftUI

struct StatusPicker: View {
    @Binding var status: ItemStatus

    var body: some View {
        HStack(spacing: 8) {
            ForEach([ItemStatus.red, .orange, .green], id: \.self) { option in
                Button {
                    status = option
                } label: {
                    Text(option.emoji)
                        .font(.title2)
                        .frame(width: 40, height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(status == option ? option.color.opacity(0.25) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(status == option ? option.color : Color.gray.opacity(0.3), lineWidth: status == option ? 2 : 1)
                        )
                        .opacity(status == option || status == .unlogged ? 1 : 0.35)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

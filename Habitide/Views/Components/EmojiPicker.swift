import SwiftUI
import UIKit

struct EmojiPickerSheet: View {
    @Binding var emoji: String
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(text.isEmpty ? "?" : text)
                    .font(.system(size: 96))
                    .frame(width: 140, height: 140)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )

                EmojiTextField(text: $text)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .focused($focused)

                Text("Tap to open the emoji keyboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    focused = true
                } label: {
                    Label("Open keyboard", systemImage: "keyboard")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.brandGreen))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.top, 32)
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Pick emoji")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        if !text.isEmpty {
                            emoji = lastEmoji(in: text) ?? text
                        }
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                text = ""
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { focused = true }
            }
            .onChange(of: text) { _, newValue in
                // Keep only the most recent character
                if newValue.count > 1, let last = newValue.last {
                    text = String(last)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func lastEmoji(in s: String) -> String? {
        for scalar in s.reversed() {
            return String(scalar)
        }
        return nil
    }
}

/// UITextField that forces the emoji keyboard.
struct EmojiTextField: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextField {
        let tf = EmojiOnlyTextField()
        tf.delegate = context.coordinator
        tf.tintColor = .clear
        tf.textColor = .clear
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        let parent: EmojiTextField
        init(_ parent: EmojiTextField) { self.parent = parent }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                parent.text = ""
                return true
            }
            parent.text = string
            return true
        }
    }
}

/// UITextField subclass that opens directly into the emoji keyboard.
final class EmojiOnlyTextField: UITextField {
    override var textInputContextIdentifier: String? { "" }
    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
    }
}

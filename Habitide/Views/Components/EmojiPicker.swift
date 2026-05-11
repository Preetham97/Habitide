import SwiftUI
import UIKit

struct EmojiPickerSheet: View {
    @Binding var emoji: String
    @Environment(\.dismiss) private var dismiss

    @State private var text: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(text.isEmpty ? "?" : text)
                    .font(.system(size: 84))
                    .frame(width: 130, height: 130)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .padding(.top, 12)

                Text("Pick from your keyboard")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                EmojiTextField(text: $text)
                    .frame(width: 1, height: 1)
                    .opacity(0.01)
                    .focused($focused)

                Spacer()
            }
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
                        if !text.isEmpty { emoji = text }
                        dismiss()
                    }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .disabled(text.isEmpty)
                }
            }
            .onAppear {
                text = ""
                focused = true
            }
            .onChange(of: text) { _, newValue in
                if newValue.count > 1, let last = newValue.last {
                    text = String(last)
                }
            }
        }
        .presentationDetents([.large])
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
            if string.isEmpty { parent.text = ""; return true }
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

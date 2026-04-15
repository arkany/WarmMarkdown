import SwiftUI

/// Shown as a sheet when the user triggers a provocation without an API key set,
/// and also available as the standard macOS Settings window (Cmd+,).
struct APIKeySetupView: View {
    var onSave: (() -> Void)? = nil

    @State private var keyInput: String
    @State private var isVisible = false
    @Environment(\.dismiss) private var dismiss

    private let warmAmber = Color(red: 0.76, green: 0.50, blue: 0.10)

    init(onSave: (() -> Void)? = nil) {
        self.onSave = onSave
        _keyInput = State(initialValue: AnthropicService.shared.apiKey ?? "")
    }

    var body: some View {
        VStack(spacing: 28) {

            // Header
            VStack(spacing: 10) {
                Text("✦")
                    .font(.system(size: 34))
                    .foregroundStyle(warmAmber)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.6)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.05), value: isVisible)

                Text("Anthropic API Key")
                    .font(.system(size: 17, weight: .semibold))
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.1), value: isVisible)

                Text("WarmMarkdown uses Claude to generate provocations.\nYour key is stored locally on this device only.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .opacity(isVisible ? 1 : 0)
                    .animation(.easeOut(duration: 0.3).delay(0.15), value: isVisible)
            }

            // Key input
            VStack(alignment: .leading, spacing: 8) {
                SecureField("sk-ant-api03-…", text: $keyInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .frame(width: 320)

                Link("Get a key at console.anthropic.com →",
                     destination: URL(string: "https://console.anthropic.com")!)
                    .font(.system(size: 11))
                    .foregroundStyle(warmAmber.opacity(0.85))
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.2), value: isVisible)

            // Actions
            HStack(spacing: 12) {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Button("Save Key") {
                    saveAndDismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(warmAmber)
                .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .opacity(isVisible ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.25), value: isVisible)
        }
        .padding(36)
        .frame(width: 420)
        .onAppear { isVisible = true }
    }

    private func saveAndDismiss() {
        let trimmed = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        AnthropicService.shared.apiKey = trimmed.isEmpty ? nil : trimmed
        onSave?()
        dismiss()
    }
}

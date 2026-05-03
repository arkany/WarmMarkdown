import SwiftUI

// Notification names for editor formatting actions
extension Notification.Name {
    static let editorBold = Notification.Name("editorBold")
    static let editorItalic = Notification.Name("editorItalic")
    static let editorLink = Notification.Name("editorLink")
    static let editorChecklist = Notification.Name("editorChecklist")
    static let editorImage = Notification.Name("editorImage")
}

struct FloatingToolbar: View {
    let theme: MarkdownTheme
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 2) {
            ToolbarButton(icon: "bold", theme: theme) {
                NotificationCenter.default.post(name: .editorBold, object: nil)
            }
            ToolbarButton(icon: "italic", theme: theme) {
                NotificationCenter.default.post(name: .editorItalic, object: nil)
            }
            ToolbarButton(icon: "link", theme: theme) {
                NotificationCenter.default.post(name: .editorLink, object: nil)
            }

            Divider()
                .frame(height: 16)
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 4)

            ToolbarButton(icon: "checklist", theme: theme) {
                NotificationCenter.default.post(name: .editorChecklist, object: nil)
            }
            ToolbarButton(icon: "photo", theme: theme) {
                NotificationCenter.default.post(name: .editorImage, object: nil)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(theme.floatingToolbarBackground).opacity(0.95))
                .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .scaleEffect(appeared ? 1 : 0.98)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.8), value: appeared)
        .onAppear { appeared = true }
    }
}

struct ToolbarButton: View {
    let icon: String
    let theme: MarkdownTheme
    let action: () -> Void
    @State private var isHovered = false

    private var isDarkToolbar: Bool { !theme.isDark }

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(isDarkToolbar ? .white : .black)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isHovered ? Color.white.opacity(isDarkToolbar ? 0.1 : 0.15) : Color.clear)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

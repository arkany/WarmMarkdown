import SwiftUI

struct FloatingToolbar: View {
    let theme: MarkdownTheme
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 2) {
            ToolbarButton(icon: "bold", theme: theme)
            ToolbarButton(icon: "italic", theme: theme)
            ToolbarButton(icon: "link", theme: theme)

            Divider()
                .frame(height: 16)
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 4)

            ToolbarButton(icon: "checklist", theme: theme)
            ToolbarButton(icon: "photo", theme: theme)
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
    @State private var isHovered = false

    private var isDarkToolbar: Bool { !theme.isDark }

    var body: some View {
        Button {} label: {
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

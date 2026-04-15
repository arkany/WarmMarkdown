import SwiftUI

struct EditorToolbar: View {
    let theme: MarkdownTheme
    let note: NoteDocument?
    @Binding var showAIPane: Bool
    var aiCommentManager: AICommentManager? = nil
    @State private var appeared = false
    @State private var isToolbarHovered = false

    var body: some View {
        HStack {
            // Left: last edited info
            HStack(spacing: 6) {
                Text(lastEditedText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(theme.sidebarTextMuted))
                    .tracking(0.5)

                Circle()
                    .fill(Color(theme.sidebarBorder))
                    .frame(width: 3, height: 3)

                Text("SAVED")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(theme.accentColor))
                    .tracking(0.5)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: appeared)

            Spacer()

            // Centre: provoke hint or generating indicator
            if let manager = aiCommentManager, note != nil {
                if manager.isGenerating {
                    HStack(spacing: 5) {
                        ProgressView()
                            .scaleEffect(0.55)
                            .frame(width: 12, height: 12)
                        Text("thinking…")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(theme.sidebarTextMuted).opacity(0.7))
                            .tracking(0.3)
                    }
                    .transition(.opacity)
                } else {
                    Text("⌘' · provoke")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color(theme.sidebarTextMuted).opacity(0.22))
                        .tracking(0.4)
                        .transition(.opacity)
                }
            }

            Spacer()

            // Right: actions
            HStack(spacing: 10) {
                Button {} label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(theme.tagTextColor))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)

                Divider()
                    .frame(height: 16)
                    .background(Color(theme.sidebarBorder))

                // AI Assistant toggle
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        showAIPane.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(theme.accentColor))
                        Text("Assistant")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(theme.sidebarTextPrimary))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color(theme.sidebarBackground))
                            .shadow(color: .black.opacity(0.04), radius: 1, y: 1)
                            .overlay(
                                Capsule()
                                    .strokeBorder(Color.black.opacity(0.04), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: appeared)
        }
        .padding(.horizontal, 24)
        .frame(height: 52)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(theme.toolbarDivider))
                .frame(height: 1)
                .opacity(isToolbarHovered ? 1 : 0)
                .animation(.easeInOut(duration: 0.5), value: isToolbarHovered)
        }
        .contentShape(Rectangle())
        .onHover { hovering in
            isToolbarHovered = hovering
        }
        .onAppear { appeared = true }
        .animation(.easeInOut(duration: 0.3), value: aiCommentManager?.isGenerating)
    }

    private var lastEditedText: String {
        guard let note = note else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "LAST EDITED TODAY \(formatter.string(from: note.lastModified).uppercased())"
    }
}

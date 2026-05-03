import SwiftUI

struct EditorToolbar: View {
    let theme: MarkdownTheme
    let note: NoteDocument?
    @Binding var showAIPane: Bool
    @State private var appeared = false
    @State private var isToolbarHovered = false
    @State private var showFormattingTips = false

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

            // Right: actions
            HStack(spacing: 10) {
                Button {
                    showFormattingTips.toggle()
                } label: {
                    Image(systemName: "number")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(theme.tagTextColor))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .help("Markdown Formatting Tips")
                .popover(isPresented: $showFormattingTips, arrowEdge: .bottom) {
                    MarkdownTipsView(theme: theme)
                }

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
    }

    private var lastEditedText: String {
        guard let note = note else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "LAST EDITED TODAY \(formatter.string(from: note.lastModified).uppercased())"
    }
}

// MARK: - Markdown Formatting Tips

struct MarkdownTipsView: View {
    let theme: MarkdownTheme

    private let tips: [(syntax: String, description: String)] = [
        ("# Heading 1", "Large heading"),
        ("## Heading 2", "Medium heading"),
        ("### Heading 3", "Small heading"),
        ("**bold**", "Bold text"),
        ("*italic*", "Italic text"),
        ("~~strikethrough~~", "Strikethrough"),
        ("`code`", "Inline code"),
        ("```\ncode block\n```", "Code block"),
        ("[text](url)", "Hyperlink"),
        ("![alt](path)", "Image"),
        ("- item", "Unordered list"),
        ("1. item", "Ordered list"),
        ("- [ ] task", "Task (unchecked)"),
        ("- [x] task", "Task (checked)"),
        ("> quote", "Blockquote"),
        ("---", "Horizontal rule"),
        ("[[page]]", "Wiki link"),
        ("#tag", "Tag"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MARKDOWN FORMATTING")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color(theme.sidebarTextMuted))
                .tracking(1)
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(tips, id: \.syntax) { tip in
                        HStack(spacing: 12) {
                            Text(tip.syntax)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color(theme.foreground))
                                .frame(maxWidth: 160, alignment: .leading)

                            Text(tip.description)
                                .font(.system(size: 12))
                                .foregroundStyle(Color(theme.sidebarTextMuted))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.vertical, 6)
            }

            Divider()

            HStack(spacing: 4) {
                Image(systemName: "keyboard")
                    .font(.system(size: 10))
                Text("Cmd+Shift+T to toggle tasks")
                    .font(.system(size: 10))
            }
            .foregroundStyle(Color(theme.sidebarTextMuted))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 340, height: 420)
        .background(Color(theme.aiPaneBackground))
    }
}

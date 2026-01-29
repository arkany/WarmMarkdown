import SwiftUI

// MARK: - AI Chat Message Model

struct AIChatMessage: Identifiable {
    let id = UUID()
    let isAI: Bool
    let text: String
    let suggestion: String?
    let timestamp: Date

    init(isAI: Bool, text: String, suggestion: String? = nil, timestamp: Date = Date()) {
        self.isAI = isAI
        self.text = text
        self.suggestion = suggestion
        self.timestamp = timestamp
    }
}

// MARK: - AI Assistant Pane

struct AIAssistantPane: View {
    let theme: MarkdownTheme
    @State private var inputText = ""
    @State private var appeared = false
    @State private var isTyping = true

    private let sampleMessages: [AIChatMessage] = [
        AIChatMessage(isAI: true, text: "Hi there. I've analyzed your document. The tone feels clear and focused. Would you like me to help expand on any section?"),
        AIChatMessage(isAI: false, text: "Can you check the flow between the introduction and the quote? It feels abrupt."),
        AIChatMessage(isAI: true, text: "I see what you mean. We could bridge it with a transition sentence, or move the quote to the end.", suggestion: "This philosophy is best captured by the timeless words..."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(theme.accentColor))
                    Text("Editor AI")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(theme.foreground))
                }

                Spacer()

                HStack(spacing: 4) {
                    Button {
                        // History
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(theme.sidebarTextMuted))
                    }
                    .buttonStyle(.plain)

                    Button {
                        // Close
                    } label: {
                        Image(systemName: "xmark.square")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(theme.sidebarTextMuted))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .overlay(alignment: .bottom) {
                Divider().background(Color(theme.toolbarDivider))
            }

            // Chat area
            ScrollView {
                VStack(spacing: 18) {
                    // Timestamp
                    Text("TODAY \(formattedTime)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(theme.sidebarTextMuted))
                        .tracking(0.8)
                        .padding(.top, 8)

                    ForEach(sampleMessages) { message in
                        if message.isAI {
                            AIMessageBubble(message: message, theme: theme)
                        } else {
                            UserMessageBubble(message: message, theme: theme)
                        }
                    }

                    // Typing indicator
                    if isTyping {
                        HStack(alignment: .top, spacing: 8) {
                            AIAvatar(theme: theme)
                            TypingIndicator(theme: theme)
                            Spacer()
                        }
                    }
                }
                .padding(16)
            }

            // Input area
            VStack(spacing: 6) {
                VStack(spacing: 0) {
                    TextField("Ask AI to edit, summarize, or translate...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .lineLimit(1...4)
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                        .padding(.bottom, 4)

                    HStack {
                        HStack(spacing: 2) {
                            Button {} label: {
                                Image(systemName: "mic")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(theme.sidebarTextMuted))
                                    .frame(width: 26, height: 26)
                            }
                            .buttonStyle(.plain)

                            Button {} label: {
                                Image(systemName: "paperclip")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color(theme.sidebarTextMuted))
                                    .frame(width: 26, height: 26)
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()

                        Button {
                            // Send
                        } label: {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 26, height: 26)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(theme.sidebarTextPrimary))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 6)
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color(theme.inputBorder), lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(theme.aiPaneBackground))
                        )
                )

                Text("AI can make mistakes. Check important info.")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(theme.sidebarTextMuted).opacity(0.7))
            }
            .padding(12)
            .overlay(alignment: .top) {
                Divider().background(Color(theme.toolbarDivider))
            }
        }
        .frame(width: 320)
        .background(Color(theme.aiPaneBackground).opacity(0.98))
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : 20)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)
        .onAppear { appeared = true }
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date()).uppercased()
    }
}

// MARK: - AI Avatar

struct AIAvatar: View {
    let theme: MarkdownTheme

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(theme.aiBubbleBackground), Color(theme.sidebarItemActive)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 26, height: 26)
            .overlay(
                Circle().strokeBorder(Color(theme.sidebarBorder), lineWidth: 1)
            )
            .overlay(
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(theme.accentColor))
            )
    }
}

// MARK: - AI Message Bubble

struct AIMessageBubble: View {
    let message: AIChatMessage
    let theme: MarkdownTheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            AIAvatar(theme: theme)

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(message.text)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(theme.foreground))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)

                    if let suggestion = message.suggestion {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("SUGGESTION:")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(Color(theme.sidebarTextMuted))
                                .padding(.top, 8)

                            Text("\"\(suggestion)\"")
                                .font(.system(size: 12))
                                .italic()
                                .foregroundStyle(Color(theme.foreground))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(theme.aiPaneBackground))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6)
                                                .strokeBorder(Color(theme.sidebarBorder), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(12)
                .background(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 4,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 14,
                        topTrailingRadius: 14
                    )
                    .fill(Color(theme.aiBubbleBackground))
                    .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 4,
                        bottomLeadingRadius: 14,
                        bottomTrailingRadius: 14,
                        topTrailingRadius: 14
                    )
                    .strokeBorder(Color.black.opacity(0.02), lineWidth: 1)
                )

                // Action chips
                if message.suggestion != nil {
                    HStack(spacing: 6) {
                        ActionChip(label: "Insert suggestion", theme: theme)
                        ActionChip(label: "Try another one", theme: theme)
                    }
                }
            }

            Spacer(minLength: 0)
        }
    }
}

// MARK: - User Message Bubble

struct UserMessageBubble: View {
    let message: AIChatMessage
    let theme: MarkdownTheme

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 6) {
                Text(message.text)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(theme.foreground))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .background(
                        UnevenRoundedRectangle(
                            topLeadingRadius: 14,
                            bottomLeadingRadius: 14,
                            bottomTrailingRadius: 14,
                            topTrailingRadius: 4
                        )
                        .fill(Color(theme.userBubbleBackground))
                        .overlay(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 14,
                                bottomLeadingRadius: 14,
                                bottomTrailingRadius: 14,
                                topTrailingRadius: 4
                            )
                            .strokeBorder(Color(theme.sidebarBorder), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 2, y: 1)
                    )
            }

            // User avatar
            Circle()
                .fill(Color(theme.foreground))
                .frame(width: 26, height: 26)
                .overlay(
                    Text(userInitials)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }

    private var userInitials: String {
        let name = NSFullUserName()
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}

// MARK: - Action Chip

struct ActionChip: View {
    let label: String
    let theme: MarkdownTheme
    @State private var isHovered = false

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(isHovered ? Color(theme.accentColor) : Color(theme.tagTextColor))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(theme.aiPaneBackground))
                    .overlay(
                        Capsule()
                            .strokeBorder(isHovered ? Color(theme.accentColor) : Color(theme.sidebarBorder), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
            )
            .contentShape(Capsule())
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    let theme: MarkdownTheme
    @State private var animating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(theme.sidebarTextMuted).opacity(0.5))
                    .frame(width: 5, height: 5)
                    .scaleEffect(animating ? 1.0 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever(autoreverses: true)
                        .delay(Double(index) * 0.15),
                        value: animating
                    )
            }
        }
        .frame(height: 36)
        .padding(.horizontal, 8)
        .onAppear { animating = true }
    }
}

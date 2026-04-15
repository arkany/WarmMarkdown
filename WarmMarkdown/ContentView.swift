import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var showAIPane = true

    private var theme: MarkdownTheme { appState.themeManager.currentTheme }

    var body: some View {
        @Bindable var state = appState

        HStack(spacing: 0) {
            // Left sidebar
            if state.sidebarVisible {
                SidebarView()
                    .overlay(alignment: .trailing) {
                        Rectangle()
                            .fill(Color(theme.sidebarBorder))
                            .frame(width: 1)
                    }
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            // Main editor area
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    // Top toolbar
                    EditorToolbar(
                        theme: theme,
                        note: state.selectedNote,
                        showAIPane: $showAIPane,
                        aiCommentManager: appState.aiCommentManager
                    )

                    // Editor content
                    if let note = state.selectedNote {
                        MarkdownEditorView(note: Binding(
                            get: { note },
                            set: { state.selectedNote = $0 }
                        ))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(theme.sidebarTextMuted).opacity(0.4))
                            Text("Select or create a note")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(theme.sidebarTextMuted))
                            Button("New Note") {
                                state.createNewNote()
                            }
                            .keyboardShortcut("n")
                            .buttonStyle(.plain)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(theme.accentColor))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(theme.aiBubbleBackground))
                            )
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .background(Color(theme.background))

                // Scroll fade at bottom
                LinearGradient(
                    colors: [Color(theme.background).opacity(0), Color(theme.background)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)

                // Floating formatting toolbar
                FloatingToolbar(theme: theme)
                    .padding(.bottom, 24)
            }

            // Quick switcher overlay
            .overlay {
                if state.showQuickSwitcher {
                    QuickSwitcherOverlay()
                }
            }

            // Right AI pane
            if showAIPane {
                AIAssistantPane(theme: theme)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color(theme.aiPaneBorder))
                            .frame(width: 1)
                    }
                    .shadow(color: .black.opacity(0.05), radius: 12, x: -4)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: state.sidebarVisible)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showAIPane)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation {
                        state.sidebarVisible.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.leading")
                }
                .help("Toggle Sidebar")
            }

            ToolbarItem(placement: .principal) {
                if let note = state.selectedNote {
                    Text(note.title)
                        .font(.headline)
                }
            }

            ToolbarItem(placement: .status) {
                if let note = state.selectedNote {
                    Text(wordCountLabel(for: note.content))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(appState.themeManager.availableThemes) { themeOption in
                        Button(themeOption.name) {
                            appState.themeManager.selectTheme(themeOption)
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                }
                .help("Switch Theme")
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak appState] event in
                guard let appState else { return event }
                let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let keyCode = event.keyCode

                // Cmd+P — Quick Switcher
                if mods == .command && keyCode == 35 {
                    appState.showQuickSwitcher.toggle()
                    return nil
                }
                // Cmd+\ — Toggle Sidebar
                if mods == .command && keyCode == 42 {
                    withAnimation { appState.sidebarVisible.toggle() }
                    return nil
                }
                // Cmd+' (keyCode 39) — inline provocation
                if mods == .command && keyCode == 39 {
                    guard appState.selectedNote != nil else { return event }
                    appState.aiCommentManager.requestProvocation()
                    return nil
                }
                // Cmd+Shift+' (keyCode 39) — coach pass
                if mods == [.command, .shift] && keyCode == 39 {
                    guard appState.selectedNote != nil else { return event }
                    appState.aiCommentManager.requestCoachPass()
                    return nil
                }
                return event
            }
        }
        .onChange(of: appState.selectedNote?.id) { _, _ in
            // Clear AI comments whenever the note selection changes
            appState.aiCommentManager.clearAll()
        }
    }
}

private func wordCountLabel(for content: String) -> String {
    let words = content.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }
    let chars = content.count
    return "\(words.count) words · \(chars) chars"
}

struct QuickSwitcherOverlay: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        QuickSwitcher()
            .frame(width: 500)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 20)
            .padding(.top, 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Color.black.opacity(0.3))
            .onTapGesture {
                appState.showQuickSwitcher = false
            }
    }
}

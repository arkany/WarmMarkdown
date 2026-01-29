import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: Binding(
            get: { state.sidebarVisible ? .all : .detailOnly },
            set: { state.sidebarVisible = ($0 != .detailOnly) }
        )) {
            SidebarView()
        } detail: {
            ZStack {
                if let note = state.selectedNote {
                    MarkdownEditorView(note: Binding(
                        get: { note },
                        set: { state.selectedNote = $0 }
                    ))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Select or create a note")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Button("New Note") {
                            state.createNewNote()
                        }
                        .keyboardShortcut("n")
                    }
                }

                if state.showQuickSwitcher {
                    QuickSwitcherOverlay()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(appState.themeManager.currentTheme.background))
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    state.sidebarVisible.toggle()
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

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ForEach(appState.themeManager.availableThemes) { theme in
                        Button(theme.name) {
                            appState.themeManager.selectTheme(theme)
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette")
                }
                .help("Switch Theme")
            }
        }
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 35 { // Cmd+P
                    state.showQuickSwitcher.toggle()
                    return nil
                }
                if event.modifierFlags.contains(.command) && event.keyCode == 42 { // Cmd+\
                    state.sidebarVisible.toggle()
                    return nil
                }
                return event
            }
        }
    }
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

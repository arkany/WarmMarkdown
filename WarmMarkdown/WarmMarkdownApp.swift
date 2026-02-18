import SwiftUI

@main
struct WarmMarkdownApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 700, minHeight: 500)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1320, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    appState.createNewNote()
                }
                .keyboardShortcut("n")
            }
            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    appState.pickFolder()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])

                Divider()

                Button("Quick Switcher") {
                    appState.showQuickSwitcher = true
                }
                .keyboardShortcut("p")
            }
            CommandMenu("Themes") {
                ForEach(appState.themeManager.availableThemes) { theme in
                    Button(theme.name) {
                        appState.themeManager.selectTheme(theme)
                    }
                }
                Divider()
                Button("Import Theme...") {
                    appState.importTheme()
                }
            }
        }
    }
}

@Observable
final class AppState {
    var fileManager = FileManagerService()
    var themeManager = ThemeManager()
    var selectedNote: NoteDocument?
    var showQuickSwitcher = false
    var sidebarVisible = true
    var activeTag: String? = nil

    init() {
        fileManager.loadNotes()
    }

    func createNewNote() {
        let note = fileManager.createNote(title: "Untitled")
        selectedNote = note
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder for your notes"
        if panel.runModal() == .OK, let url = panel.url {
            fileManager.notesDirectory = url
            UserDefaults.standard.set(url.path, forKey: "notesDirectory")
            fileManager.loadNotes()
        }
    }

    func importTheme() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.message = "Select a VSCode theme JSON file"
        if panel.runModal() == .OK, let url = panel.url {
            themeManager.importTheme(from: url)
        }
    }
}

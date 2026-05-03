import SwiftUI

@main
struct WarmMarkdownApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 700, minHeight: 500)
                .onOpenURL { url in
                    appState.openExternalFile(url)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1320, height: 800)
        Settings {
            SettingsView()
                .environment(appState)
        }

        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    appState.createNewNote()
                }
                .keyboardShortcut("n")
            }
            CommandGroup(after: .newItem) {
                Button("Open File...") {
                    appState.openFile()
                }

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
    var recentDocuments = RecentDocumentsService()
    var selectedNote: NoteDocument?
    var showQuickSwitcher = false
    var sidebarVisible = true
    var activeTag: String? = nil

    init() {
        fileManager.loadNotes()
        restoreSelectedNote()
    }

    private func restoreSelectedNote() {
        if let savedPath = UserDefaults.standard.string(forKey: "selectedNotePath"),
           let note = fileManager.notes.first(where: { $0.fileURL.path == savedPath }) {
            selectedNote = note
        } else if let first = fileManager.notes.first {
            selectedNote = first
        }
        // On first launch (no history yet), seed from notes sorted by modification date.
        // Reversed so that after all insert-at-0 calls the most-recent note ends up first.
        if recentDocuments.entries.isEmpty {
            for note in fileManager.notes.prefix(10).reversed() {
                recentDocuments.record(path: note.fileURL.path, title: note.displayTitle)
            }
        }
    }

    func saveSelectedNotePath() {
        if let note = selectedNote {
            UserDefaults.standard.set(note.fileURL.path, forKey: "selectedNotePath")
        }
    }

    func createNewNote() {
        let note = fileManager.createNote(title: "Untitled")
        selectedNote = note
        saveSelectedNotePath()
        recentDocuments.record(path: note.fileURL.path, title: note.displayTitle)
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

    func openFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!]
        panel.message = "Open a Markdown file"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        openExternalFile(url)
    }

    func openExternalFile(_ url: URL) {
        guard url.pathExtension.lowercased() == "md" ||
              url.pathExtension.lowercased() == "markdown" else { return }

        // If the file is inside the notes directory, just select it from the list
        if fileManager.isInNotesDirectory(url) {
            if let existing = fileManager.notes.first(where: { $0.fileURL == url }) {
                selectedNote = existing
                recentDocuments.record(path: url.path, title: existing.displayTitle)
                saveSelectedNotePath()
            } else {
                // File exists in directory but not yet loaded — refresh then select
                fileManager.loadNotes()
                if let note = fileManager.notes.first(where: { $0.fileURL == url }) {
                    selectedNote = note
                    recentDocuments.record(path: url.path, title: note.displayTitle)
                    saveSelectedNotePath()
                }
            }
            return
        }

        // External file: load it, create a security-scoped bookmark, inject into the list
        guard let note = fileManager.loadExternalFile(at: url) else { return }

        // Create a security-scoped bookmark so we can reopen it later
        let bookmark = try? url.bookmarkData(options: .withSecurityScope)
        recentDocuments.record(path: url.path, title: note.displayTitle, bookmarkData: bookmark)

        // Inject into notes list if not already present, so it shows up in the sidebar
        if !fileManager.notes.contains(where: { $0.fileURL == url }) {
            fileManager.notes.insert(note, at: 0)
        }

        selectedNote = note
        saveSelectedNotePath()
    }

    /// Called when the user taps a recent entry in the sidebar.
    func openRecent(_ entry: RecentEntry) {
        // First try to find it in the already-loaded notes
        if let existing = fileManager.notes.first(where: { $0.fileURL.path == entry.path }) {
            selectedNote = existing
            recentDocuments.record(path: entry.path, title: existing.displayTitle, bookmarkData: entry.bookmarkData)
            saveSelectedNotePath()
            return
        }

        // Resolve URL (handles security-scoped bookmarks)
        guard let url = recentDocuments.resolveURL(for: entry) else {
            // File is gone — remove from recents
            recentDocuments.remove(path: entry.path)
            return
        }

        // Start access if it's a security-scoped URL
        let needsAccess = entry.bookmarkData != nil
        if needsAccess { _ = url.startAccessingSecurityScopedResource() }
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        guard let note = fileManager.loadExternalFile(at: url) else { return }

        if !fileManager.notes.contains(where: { $0.fileURL == url }) {
            fileManager.notes.insert(note, at: 0)
        }

        selectedNote = note
        recentDocuments.record(path: url.path, title: note.displayTitle, bookmarkData: entry.bookmarkData)
        saveSelectedNotePath()
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

    func recordNoteOpened(_ note: NoteDocument) {
        recentDocuments.record(path: note.fileURL.path, title: note.displayTitle)
    }
}

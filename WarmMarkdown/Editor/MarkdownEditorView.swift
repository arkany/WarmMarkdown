import SwiftUI

struct MarkdownEditorView: View {
    @Binding var note: NoteDocument
    @Environment(AppState.self) private var appState
    var body: some View {
        let formatter = MarkdownFormatter(theme: appState.themeManager.currentTheme)

        TextViewWrapper(
            text: $note.content,
            formatter: formatter,
            onTextChange: { newText in
                saveWithDebounce(content: newText)
            }
        )
        .background(Color(appState.themeManager.currentTheme.background))
    }

    private func saveWithDebounce(content: String) {
        var updated = note
        updated.content = content
        updated.title = extractTitle(from: content)
        updated.lastModified = Date()
        note = updated

        Task {
            try? await Task.sleep(for: .milliseconds(500))
            appState.fileManager.saveNote(note)
        }
    }

    private func extractTitle(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                return String(trimmed.dropFirst(2))
            }
            if !trimmed.isEmpty {
                return String(trimmed.prefix(50))
            }
        }
        return "Untitled"
    }
}

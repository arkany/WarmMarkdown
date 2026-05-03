import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceSettingsTab()
                .tabItem { Label("Appearance", systemImage: "paintpalette") }

            StorageSettingsTab()
                .tabItem { Label("Storage", systemImage: "folder") }

            EditorSettingsTab()
                .tabItem { Label("Editor", systemImage: "text.alignleft") }
        }
        .frame(width: 480, height: 320)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Active theme", selection: Binding(
                    get: { appState.themeManager.currentTheme.id },
                    set: { id in
                        if let theme = appState.themeManager.availableThemes.first(where: { $0.id == id }) {
                            appState.themeManager.selectTheme(theme)
                        }
                    }
                )) {
                    ForEach(appState.themeManager.availableThemes) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .pickerStyle(.radioGroup)

                Button("Import VSCode Theme…") {
                    appState.importTheme()
                }
                .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Storage

private struct StorageSettingsTab: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("Notes Folder") {
                LabeledContent("Location") {
                    Text(appState.fileManager.notesDirectory.abbreviatingWithTilde)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Button("Change Folder…") {
                    appState.pickFolder()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Editor

private struct EditorSettingsTab: View {
    @AppStorage("spellCheckEnabled") private var spellCheck = true
    @AppStorage("autocorrectEnabled") private var autocorrect = false
    @AppStorage("lineNumbersEnabled") private var lineNumbers = false
    @AppStorage("typewriterScrollEnabled") private var typewriterScroll = false

    var body: some View {
        Form {
            Section("Editing") {
                Toggle("Check spelling while typing", isOn: $spellCheck)
                Toggle("Correct spelling automatically", isOn: $autocorrect)
            }
            Section("Layout") {
                Toggle("Typewriter scroll (keep cursor centred)", isOn: $typewriterScroll)
                Toggle("Show line numbers", isOn: $lineNumbers)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Helper

private extension URL {
    var abbreviatingWithTilde: String {
        path.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}

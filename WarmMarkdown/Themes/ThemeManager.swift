import Foundation
import AppKit

@Observable
final class ThemeManager {
    var currentTheme: MarkdownTheme = .warmOatmeal
    var availableThemes: [MarkdownTheme] = []

    private let customThemesDirectory: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        customThemesDirectory = appSupport.appendingPathComponent("WarmMarkdown/Themes")
        try? FileManager.default.createDirectory(at: customThemesDirectory, withIntermediateDirectories: true)

        loadAllThemes()

        // Restore last selected theme
        if let savedID = UserDefaults.standard.string(forKey: "selectedThemeID"),
           let theme = availableThemes.first(where: { $0.id == savedID }) {
            currentTheme = theme
        }
    }

    func selectTheme(_ theme: MarkdownTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.id, forKey: "selectedThemeID")
    }

    func importTheme(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let vscodeTheme = try JSONDecoder().decode(VSCodeThemeFile.self, from: data)

            let name = vscodeTheme.name ?? url.deletingPathExtension().lastPathComponent
            let id = "custom-\(name.lowercased().replacingOccurrences(of: " ", with: "-"))"

            // Copy to app support
            let destURL = customThemesDirectory.appendingPathComponent(url.lastPathComponent)
            if !FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.copyItem(at: url, to: destURL)
            }

            let theme = ThemeMapper.map(from: vscodeTheme, id: id, name: name)

            if !availableThemes.contains(where: { $0.id == theme.id }) {
                availableThemes.append(theme)
            }

            selectTheme(theme)
        } catch {
            print("Failed to import theme: \(error)")
        }
    }

    private func loadAllThemes() {
        var themes: [MarkdownTheme] = []

        // Load bundled themes
        let bundledNames = ["warm-oatmeal", "dracula", "nord", "gruvbox-warm", "one-dark"]
        for name in bundledNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "json") {
                if let theme = loadTheme(from: url, id: name) {
                    themes.append(theme)
                }
            }
        }

        // If warm-oatmeal wasn't loaded from JSON, use the hardcoded default
        if !themes.contains(where: { $0.id == "warm-oatmeal" }) {
            themes.insert(.warmOatmeal, at: 0)
        }

        // Load custom imported themes
        if let customFiles = try? FileManager.default.contentsOfDirectory(
            at: customThemesDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for fileURL in customFiles where fileURL.pathExtension == "json" {
                let id = "custom-\(fileURL.deletingPathExtension().lastPathComponent)"
                if let theme = loadTheme(from: fileURL, id: id) {
                    themes.append(theme)
                }
            }
        }

        availableThemes = themes
    }

    private func loadTheme(from url: URL, id: String) -> MarkdownTheme? {
        do {
            let data = try Data(contentsOf: url)
            let vscodeTheme = try JSONDecoder().decode(VSCodeThemeFile.self, from: data)
            let name = vscodeTheme.name ?? url.deletingPathExtension().lastPathComponent
                .replacingOccurrences(of: "-", with: " ")
                .capitalized
            return ThemeMapper.map(from: vscodeTheme, id: id, name: name)
        } catch {
            print("Failed to load theme from \(url): \(error)")
            return nil
        }
    }
}

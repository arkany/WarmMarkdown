import Foundation
import AppKit

@Observable
final class FileManagerService {
    var notes: [NoteDocument] = []
    var notesDirectory: URL

    private var directoryMonitor: DispatchSourceFileSystemObject?
    private var monitorFileDescriptor: Int32 = -1

    init() {
        if let savedPath = UserDefaults.standard.string(forKey: "notesDirectory") {
            notesDirectory = URL(fileURLWithPath: savedPath)
        } else {
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            notesDirectory = documentsURL.appendingPathComponent("Notes")
        }
        ensureDirectoryExists()
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: notesDirectory, withIntermediateDirectories: true)
    }

    func loadNotes() {
        ensureDirectoryExists()
        let fm = FileManager.default

        guard let enumerator = fm.enumerator(
            at: notesDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return }

        var loaded: [NoteDocument] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension == "md" else { continue }
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .contentModificationDateKey]),
                  resourceValues.isRegularFile == true else { continue }

            if let content = try? String(contentsOf: fileURL, encoding: .utf8) {
                let title = extractTitle(from: content, fallback: fileURL.deletingPathExtension().lastPathComponent)
                let modified = resourceValues.contentModificationDate ?? Date()
                // Preserve existing UUID so selectedNote references stay valid after directory events
                let existingID = notes.first(where: { $0.fileURL == fileURL })?.id ?? UUID()
                let note = NoteDocument(id: existingID, title: title, content: content, fileURL: fileURL, lastModified: modified)
                loaded.append(note)
            }
        }

        notes = loaded.sorted { $0.lastModified > $1.lastModified }
        startDirectoryMonitoring()
    }

    func saveNote(_ note: NoteDocument) {
        do {
            try note.content.write(to: note.fileURL, atomically: true, encoding: .utf8)
            if let index = notes.firstIndex(where: { $0.id == note.id }) {
                var saved = note
                saved.lastModified = Date()
                notes[index] = saved
            }
        } catch {
            print("Failed to save note: \(error)")
        }
    }

    func createNote(title: String) -> NoteDocument {
        let baseName = sanitizeFileName(title)
        var fileName = baseName + ".md"
        var fileURL = notesDirectory.appendingPathComponent(fileName)

        // Avoid overwriting existing files
        var counter = 1
        while FileManager.default.fileExists(atPath: fileURL.path) {
            fileName = "\(baseName) \(counter).md"
            fileURL = notesDirectory.appendingPathComponent(fileName)
            counter += 1
        }

        let content = "# \(title)\n\n"
        let note = NoteDocument(title: title, content: content, fileURL: fileURL)

        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
        notes.insert(note, at: 0)

        return note
    }

    func deleteNote(_ note: NoteDocument) {
        try? FileManager.default.removeItem(at: note.fileURL)
        notes.removeAll { $0.id == note.id }
    }

    func renameNote(_ note: NoteDocument, to newTitle: String) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }

        let newFileName = sanitizeFileName(newTitle) + ".md"
        let newURL = note.fileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

        do {
            try FileManager.default.moveItem(at: note.fileURL, to: newURL)
            notes[index].fileURL = newURL
            notes[index].title = newTitle
        } catch {
            print("Failed to rename note: \(error)")
        }
    }

    // MARK: - Directory Monitoring

    private func startDirectoryMonitoring() {
        stopDirectoryMonitoring()

        monitorFileDescriptor = open(notesDirectory.path, O_EVTONLY)
        guard monitorFileDescriptor >= 0 else { return }

        directoryMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: monitorFileDescriptor,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        directoryMonitor?.setEventHandler { [weak self] in
            self?.loadNotes()
        }

        directoryMonitor?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            close(self.monitorFileDescriptor)
            self.monitorFileDescriptor = -1
        }

        directoryMonitor?.resume()
    }

    private func stopDirectoryMonitoring() {
        directoryMonitor?.cancel()
        directoryMonitor = nil
    }

    // MARK: - Helpers

    private func extractTitle(from content: String, fallback: String) -> String {
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
        return fallback
    }

    private func sanitizeFileName(_ name: String) -> String {
        let illegal = CharacterSet(charactersIn: "/\\?%*|\"<>:")
        var sanitized = name.components(separatedBy: illegal).joined(separator: "-")
        if sanitized.isEmpty { sanitized = "Untitled" }
        return sanitized
    }

    // MARK: - External File Loading

    /// Load a .md file from any location (user-selected via NSOpenPanel or Finder open).
    /// Returns a NoteDocument if the file is readable. The caller is responsible for
    /// starting/stopping security-scoped access when a bookmark URL is involved.
    func loadExternalFile(at url: URL) -> NoteDocument? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        let modified = (attrs?[.modificationDate] as? Date) ?? Date()
        let title = extractTitle(from: content, fallback: url.deletingPathExtension().lastPathComponent)
        let existingID = notes.first(where: { $0.fileURL == url })?.id ?? UUID()
        return NoteDocument(id: existingID, title: title, content: content, fileURL: url, lastModified: modified)
    }

    /// True if `url` lives inside the current notes directory.
    func isInNotesDirectory(_ url: URL) -> Bool {
        url.path.hasPrefix(notesDirectory.path)
    }

    /// Get subfolder structure for sidebar
    func folderStructure() -> [FolderItem] {
        let fm = FileManager.default
        return buildFolderItems(at: notesDirectory, using: fm)
    }

    private func buildFolderItems(at url: URL, using fm: FileManager) -> [FolderItem] {
        guard let contents = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var items: [FolderItem] = []

        for itemURL in contents.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let isDir = (try? itemURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            if isDir {
                let children = buildFolderItems(at: itemURL, using: fm)
                items.append(FolderItem(name: itemURL.lastPathComponent, url: itemURL, isFolder: true, children: children))
            } else if itemURL.pathExtension == "md" {
                items.append(FolderItem(name: itemURL.deletingPathExtension().lastPathComponent, url: itemURL, isFolder: false, children: []))
            }
        }

        return items
    }
}

struct FolderItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let url: URL
    let isFolder: Bool
    let children: [FolderItem]
}

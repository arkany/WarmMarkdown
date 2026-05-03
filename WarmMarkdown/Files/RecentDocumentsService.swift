import Foundation
import AppKit

struct RecentEntry: Codable, Identifiable {
    let id: UUID
    var path: String
    var bookmarkData: Data?
    var title: String
    var accessedAt: Date
}

@Observable
final class RecentDocumentsService {
    private(set) var entries: [RecentEntry] = []

    static let maxEntries = 15
    private static let defaultsKey = "recentDocuments"

    init() {
        load()
    }

    func record(path: String, title: String, bookmarkData: Data? = nil) {
        var updated = entries.filter { $0.path != path }
        let entry = RecentEntry(
            id: UUID(),
            path: path,
            bookmarkData: bookmarkData,
            title: title,
            accessedAt: Date()
        )
        updated.insert(entry, at: 0)
        if updated.count > Self.maxEntries {
            updated = Array(updated.prefix(Self.maxEntries))
        }
        entries = updated
        save()
    }

    func remove(path: String) {
        entries.removeAll { $0.path == path }
        save()
    }

    /// Resolve a recent entry's URL, refreshing the bookmark if needed.
    /// Returns nil if the file no longer exists or the bookmark is stale.
    func resolveURL(for entry: RecentEntry) -> URL? {
        if let data = entry.bookmarkData {
            var isStale = false
            if let url = try? URL(
                resolvingBookmarkData: data,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            ) {
                if isStale {
                    // Attempt bookmark refresh — may fail if access was revoked
                    if let fresh = try? url.bookmarkData(options: .withSecurityScope) {
                        var e = entry
                        e.bookmarkData = fresh
                        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
                            entries[idx] = e
                            save()
                        }
                    }
                }
                return url
            }
        }
        // Fall back to plain path (works inside sandbox for user-selected files)
        let url = URL(fileURLWithPath: entry.path)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
              let decoded = try? JSONDecoder().decode([RecentEntry].self, from: data)
        else { return }
        entries = decoded
    }
}

import Foundation

struct NoteDocument: Identifiable, Equatable, Hashable {
    let id: UUID
    var title: String
    var content: String
    var fileURL: URL
    var lastModified: Date
    var tags: [String]

    init(id: UUID = UUID(), title: String = "Untitled", content: String = "", fileURL: URL, lastModified: Date = Date()) {
        self.id = id
        self.title = title
        self.content = content
        self.fileURL = fileURL
        self.lastModified = lastModified
        self.tags = NoteDocument.extractTags(from: content)
    }

    static func extractTags(from content: String) -> [String] {
        let pattern = #"(?:^|\s)#([a-zA-Z][a-zA-Z0-9_-]*)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, range: range)
        var tags: [String] = []
        for match in matches {
            if let tagRange = Range(match.range(at: 1), in: content) {
                tags.append(String(content[tagRange]))
            }
        }
        return Array(Set(tags)).sorted()
    }

    mutating func updateTags() {
        tags = NoteDocument.extractTags(from: content)
    }

    /// First line of content with heading markers stripped, truncated to 20 characters.
    var displayTitle: String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
            ?? "Untitled"
        if firstLine.isEmpty { return "Untitled" }
        return String(firstLine.prefix(20))
    }

    static func == (lhs: NoteDocument, rhs: NoteDocument) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content && lhs.title == rhs.title && lhs.lastModified == rhs.lastModified
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

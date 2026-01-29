import Foundation

/// Parses and resolves [[wiki-links]] in markdown content.
final class WikiLinkParser {
    static let shared = WikiLinkParser()

    private let pattern = #"\[\[([^\]]+)\]\]"#
    private lazy var regex: NSRegularExpression? = {
        try? NSRegularExpression(pattern: pattern)
    }()

    private init() {}

    /// Find all wiki-links in text, returning their targets and ranges
    func findWikiLinks(in text: String) -> [(target: String, range: NSRange)] {
        guard let regex else { return [] }
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        let matches = regex.matches(in: text, range: fullRange)

        return matches.compactMap { match in
            let targetRange = match.range(at: 1)
            guard let r = Range(targetRange, in: text) else { return nil }
            let target = String(text[r])
            return (target: target, range: match.range)
        }
    }

    /// Resolve a wiki-link target to a note document
    func resolve(target: String, in notes: [NoteDocument]) -> NoteDocument? {
        let normalized = target.lowercased().trimmingCharacters(in: .whitespaces)

        // Exact title match
        if let note = notes.first(where: { $0.title.lowercased() == normalized }) {
            return note
        }

        // Filename match (without extension)
        if let note = notes.first(where: {
            $0.fileURL.deletingPathExtension().lastPathComponent.lowercased() == normalized
        }) {
            return note
        }

        // Fuzzy match
        let results = SearchService.shared.search(query: target, in: notes)
        return results.first
    }

    /// Replace wiki-link targets when a note is renamed
    func updateWikiLinks(in content: String, from oldTitle: String, to newTitle: String) -> String {
        return content.replacingOccurrences(of: "[[\(oldTitle)]]", with: "[[\(newTitle)]]")
    }
}

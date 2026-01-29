import Foundation

/// Fuzzy search service for notes
final class SearchService {
    static let shared = SearchService()

    private init() {}

    /// Search notes by title and content with fuzzy matching
    func search(query: String, in notes: [NoteDocument]) -> [NoteDocument] {
        let query = query.lowercased()

        let scored = notes.compactMap { note -> (NoteDocument, Double)? in
            let score = fuzzyScore(query: query, target: note.title.lowercased())
            let contentScore = note.content.lowercased().contains(query) ? 0.3 : 0
            let tagScore = note.tags.contains(where: { $0.lowercased().contains(query) }) ? 0.5 : 0

            let totalScore = score + contentScore + tagScore
            guard totalScore > 0 else { return nil }
            return (note, totalScore)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    /// Simple fuzzy matching score: returns 0-1 based on how well query matches target
    private func fuzzyScore(query: String, target: String) -> Double {
        if target == query { return 1.0 }
        if target.contains(query) { return 0.8 }
        if target.hasPrefix(query) { return 0.9 }

        // Character-by-character fuzzy matching
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex
        var matchCount = 0
        var consecutiveMatches = 0
        var maxConsecutive = 0

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                matchCount += 1
                consecutiveMatches += 1
                maxConsecutive = max(maxConsecutive, consecutiveMatches)
                queryIndex = query.index(after: queryIndex)
            } else {
                consecutiveMatches = 0
            }
            targetIndex = target.index(after: targetIndex)
        }

        guard queryIndex == query.endIndex else { return 0 }

        let matchRatio = Double(matchCount) / Double(target.count)
        let consecutiveBonus = Double(maxConsecutive) / Double(query.count) * 0.3
        return min(matchRatio + consecutiveBonus, 0.75)
    }

    /// Extract all unique tags from a collection of notes
    func extractAllTags(from notes: [NoteDocument]) -> [String] {
        let allTags = notes.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
}

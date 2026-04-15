import Foundation
import AppKit

// MARK: - Custom attribute key for AI comment ranges

extension NSAttributedString.Key {
    /// Marks characters that belong to an AI comment block (not part of the user's text).
    /// Value type: UUID — the comment's identifier.
    static let aiCommentID = NSAttributedString.Key("dev.warmmarkdown.aiCommentID")
}

// MARK: - AIComment model

struct AIComment: Identifiable, Equatable {
    let id: UUID
    let text: String
    /// The anchor paragraph's range in the *clean* (comment-free) text at time of creation.
    let anchorParagraphRange: NSRange
    var isDismissed: Bool
    let createdAt: Date

    init(text: String, anchorParagraphRange: NSRange) {
        self.id = UUID()
        self.text = text
        self.anchorParagraphRange = anchorParagraphRange
        self.isDismissed = false
        self.createdAt = Date()
    }

    static func == (lhs: AIComment, rhs: AIComment) -> Bool {
        lhs.id == rhs.id
    }
}

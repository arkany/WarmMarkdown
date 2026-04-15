import Foundation
import AppKit

/// The action the user tried to trigger before the API key was set.
/// Stored so it can be re-fired automatically after the key is saved.
enum PendingProvocationAction {
    case inline
    case coachPass
}

/// Orchestrates AI provocation comments.
/// Callbacks are set by TextViewWrapper.Coordinator to bridge into NSTextStorage.
@Observable
final class AICommentManager {

    // MARK: - State

    var comments: [AIComment] = []
    var isGenerating: Bool = false

    /// Set to true when the user triggers a provocation with no API key configured.
    /// ContentView observes this to present the API key setup sheet.
    var showAPIKeySheet: Bool = false

    /// The action that triggered the sheet, so it can be re-fired after saving.
    var pendingAction: PendingProvocationAction? = nil

    var activeComments: [AIComment] { comments.filter { !$0.isDismissed } }

    // MARK: - Callbacks (set by TextViewWrapper.Coordinator)

    /// Called when a new comment should be inserted into the text storage.
    var insertHandler: ((AIComment) -> Void)?

    /// Called when a comment should be removed from the text storage.
    var removeHandler: ((UUID) -> Void)?

    /// Triggers an inline provocation at the current cursor paragraph.
    var provocationTrigger: (() -> Void)?

    /// Triggers a full-document coach pass.
    var coachPassTrigger: (() -> Void)?

    // MARK: - Dismiss

    func dismiss(_ id: UUID) {
        if let idx = comments.firstIndex(where: { $0.id == id }) {
            comments[idx].isDismissed = true
        }
        removeHandler?(id)
    }

    func dismissMostRecent() {
        guard let last = activeComments.last else { return }
        dismiss(last.id)
    }

    func clearAll() {
        let ids = activeComments.map(\.id)
        comments.removeAll()
        for id in ids { removeHandler?(id) }
    }

    // MARK: - Trigger entry points (called from ContentView key handler)

    func requestProvocation() {
        provocationTrigger?()
    }

    func requestCoachPass() {
        coachPassTrigger?()
    }

    // MARK: - Fetch methods (called by Coordinator via triggers)

    func fetchProvocation(for paragraphText: String, anchorRange: NSRange) {
        guard !isGenerating else { return }
        guard AnthropicService.shared.apiKey != nil else {
            pendingAction = .inline
            showAPIKeySheet = true
            return
        }

        isGenerating = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isGenerating = false }
            do {
                let text = try await AnthropicService.shared.generateProvocation(for: paragraphText)
                let comment = AIComment(text: text, anchorParagraphRange: anchorRange)
                self.comments.append(comment)
                self.insertHandler?(comment)
            } catch AnthropicError.missingAPIKey {
                // Silently ignore — no key configured yet
            } catch {
                print("[AICommentManager] Provocation error: \(error)")
            }
        }
    }

    func fetchCoachPass(for fullText: String) {
        guard !isGenerating else { return }
        guard AnthropicService.shared.apiKey != nil else {
            pendingAction = .coachPass
            showAPIKeySheet = true
            return
        }

        isGenerating = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.isGenerating = false }
            do {
                let rawComments = try await AnthropicService.shared.runCoachPass(on: fullText)
                let nsText = fullText as NSString

                for (index, raw) in rawComments.enumerated() {
                    // Find the anchor phrase in the clean text
                    let searchRange = NSRange(location: 0, length: nsText.length)
                    let anchorRange = nsText.range(of: raw.anchorText, options: .caseInsensitive, range: searchRange)
                    guard anchorRange.location != NSNotFound else { continue }

                    let paragraphRange = nsText.paragraphRange(for: anchorRange)
                    let comment = AIComment(text: raw.comment, anchorParagraphRange: paragraphRange)

                    // Stagger insertions for a pleasant sequential reveal
                    if index > 0 {
                        try? await Task.sleep(for: .milliseconds(700))
                    }
                    self.comments.append(comment)
                    self.insertHandler?(comment)
                }
            } catch AnthropicError.missingAPIKey {
                // Silently ignore
            } catch {
                print("[AICommentManager] Coach pass error: \(error)")
            }
        }
    }
}

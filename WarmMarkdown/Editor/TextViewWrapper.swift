import SwiftUI
import AppKit

struct TextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    var formatter: MarkdownFormatter
    var aiCommentManager: AICommentManager
    var onTextChange: (String) -> Void
    var onTaskToggle: ((Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true
        textView.textContainerInset = NSSize(width: 60, height: 36)
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineFragmentPadding = 0
        textView.font = .systemFont(ofSize: 15)

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        context.coordinator.textView = textView
        context.coordinator.setupCommentCallbacks()
        context.coordinator.applyFormatting()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.parent = self

        // Compare only the *clean* text to avoid clobbering embedded comment blocks
        // during normal typing (where the storage text ≠ the clean text binding).
        let currentClean = context.coordinator.extractCleanText()
        if currentClean != text {
            // Underlying note content changed (e.g. note switch or programmatic edit).
            // Reset the storage to the new clean text; comments will be cleared.
            let selectedRanges = textView.selectedRanges
            context.coordinator.isModifyingComments = true
            textView.string = text
            context.coordinator.isModifyingComments = false
            context.coordinator.applyFormatting()
            let safeRanges = selectedRanges.filter {
                ($0 as! NSValue).rangeValue.upperBound <= text.utf16.count
            }
            textView.selectedRanges = safeRanges.isEmpty ? [NSValue(range: NSRange(location: 0, length: 0))] : safeRanges
        }

        textView.backgroundColor = formatter.theme.background
        scrollView.backgroundColor = formatter.theme.background
        textView.insertionPointColor = formatter.theme.accentColor
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: TextViewWrapper
        weak var textView: NSTextView?
        var isFormatting = false
        var isModifyingComments = false
        private var debounceTask: Task<Void, Never>?

        init(_ parent: TextViewWrapper) {
            self.parent = parent
            super.init()
        }

        // MARK: Setup

        func setupCommentCallbacks() {
            let manager = parent.aiCommentManager
            manager.insertHandler = { [weak self] comment in
                self?.insertComment(comment)
            }
            manager.removeHandler = { [weak self] id in
                self?.removeComment(id: id)
            }
            manager.provocationTrigger = { [weak self] in
                self?.triggerProvocationAtCursor()
            }
            manager.coachPassTrigger = { [weak self] in
                self?.triggerCoachPass()
            }
        }

        // MARK: - Clean text helpers

        /// Returns the user's text with all AI comment characters stripped.
        func extractCleanText() -> String {
            guard let textStorage = textView?.textStorage else { return parent.text }
            let full = textStorage.string
            var result = ""
            result.reserveCapacity(full.count)
            var pos = 0
            for ch in full.unicodeScalars {
                if pos < textStorage.length,
                   textStorage.attribute(.aiCommentID, at: pos, effectiveRange: nil) == nil {
                    result.unicodeScalars.append(ch)
                }
                pos += 1
            }
            return result
        }

        /// Converts a position in clean text space to the equivalent position in storage space.
        func storagePosition(forCleanPosition cleanPos: Int) -> Int {
            guard let textStorage = textView?.textStorage else { return cleanPos }
            var cleanCount = 0
            var storagePos = 0
            let length = textStorage.length
            while storagePos < length && cleanCount < cleanPos {
                if textStorage.attribute(.aiCommentID, at: storagePos, effectiveRange: nil) == nil {
                    cleanCount += 1
                }
                storagePos += 1
            }
            // Advance past any comment characters sitting at this storage position
            while storagePos < length,
                  textStorage.attribute(.aiCommentID, at: storagePos, effectiveRange: nil) != nil {
                storagePos += 1
            }
            return storagePos
        }

        /// Converts a storage position to the equivalent clean-text position.
        func cleanPosition(forStoragePosition storagePos: Int) -> Int {
            guard let textStorage = textView?.textStorage else { return storagePos }
            var cleanCount = 0
            for i in 0..<min(storagePos, textStorage.length) {
                if textStorage.attribute(.aiCommentID, at: i, effectiveRange: nil) == nil {
                    cleanCount += 1
                }
            }
            return cleanCount
        }

        // MARK: - Comment insertion / removal

        func insertComment(_ comment: AIComment) {
            guard let textView = textView, let textStorage = textView.textStorage else { return }

            // Find the storage insertion point for the end of the anchor paragraph
            let insertionStoragePos = storagePosition(forCleanPosition: comment.anchorParagraphRange.location + comment.anchorParagraphRange.length)

            let commentAS = buildCommentAttributedString(comment)

            isModifyingComments = true
            textStorage.beginEditing()
            textStorage.insert(commentAS, at: min(insertionStoragePos, textStorage.length))
            textStorage.endEditing()
            isModifyingComments = false
        }

        func removeComment(id: UUID) {
            guard let textView = textView, let textStorage = textView.textStorage else { return }

            // Find the contiguous range marked with this comment's UUID
            var commentRange = NSRange(location: NSNotFound, length: 0)
            var pos = 0
            while pos < textStorage.length {
                var effectiveRange = NSRange()
                if let val = textStorage.attribute(.aiCommentID, at: pos, effectiveRange: &effectiveRange) as? UUID,
                   val == id {
                    if commentRange.location == NSNotFound {
                        commentRange = effectiveRange
                    } else {
                        let lo = min(commentRange.location, effectiveRange.location)
                        let hi = max(commentRange.location + commentRange.length,
                                     effectiveRange.location + effectiveRange.length)
                        commentRange = NSRange(location: lo, length: hi - lo)
                    }
                    pos = effectiveRange.location + effectiveRange.length
                } else {
                    pos += 1
                }
            }

            guard commentRange.location != NSNotFound,
                  commentRange.location + commentRange.length <= textStorage.length else { return }

            isModifyingComments = true
            textStorage.beginEditing()
            textStorage.deleteCharacters(in: commentRange)
            textStorage.endEditing()
            isModifyingComments = false

            applyFormatting()
        }

        private func buildCommentAttributedString(_ comment: AIComment) -> NSAttributedString {
            let id = comment.id
            let warmAmber = NSColor(red: 0.76, green: 0.50, blue: 0.10, alpha: 1.0)
            let dismissAmber = NSColor(red: 0.76, green: 0.50, blue: 0.10, alpha: 0.50)
            let commentFont = NSFont(name: "Georgia-Italic", size: 14)
                ?? NSFont.systemFont(ofSize: 14).with(traits: .italic)
            let dismissFont = NSFont.systemFont(ofSize: 12)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 3
            paragraphStyle.paragraphSpacingBefore = 4
            paragraphStyle.paragraphSpacing = 6

            let baseAttrs: [NSAttributedString.Key: Any] = [
                .font: commentFont,
                .foregroundColor: warmAmber,
                .paragraphStyle: paragraphStyle,
                .aiCommentID: id
            ]
            let dismissAttrs: [NSAttributedString.Key: Any] = [
                .font: dismissFont,
                .foregroundColor: dismissAmber,
                .link: "warmmarkdown://dismiss/\(id.uuidString)" as AnyObject,
                .aiCommentID: id
            ]
            let nlAttrs: [NSAttributedString.Key: Any] = [
                .font: commentFont,
                .paragraphStyle: paragraphStyle,
                .aiCommentID: id
            ]

            let mutable = NSMutableAttributedString()
            // Leading newline creates visual separation from the paragraph above
            mutable.append(NSAttributedString(string: "\n", attributes: nlAttrs))
            // Sparkle + comment text
            mutable.append(NSAttributedString(string: "✦  \(comment.text)", attributes: baseAttrs))
            // Dismiss link
            mutable.append(NSAttributedString(string: "  ×", attributes: dismissAttrs))
            // Trailing newline closes the block
            mutable.append(NSAttributedString(string: "\n", attributes: nlAttrs))
            return mutable
        }

        // MARK: - Provocation triggers (called from manager callbacks)

        private func triggerProvocationAtCursor() {
            guard let textView = textView else { return }
            let cleanText = parent.text
            guard !cleanText.isEmpty else { return }

            // Map storage cursor position → clean text position → paragraph range
            let storageCursor = textView.selectedRange().location
            let cleanCursor = cleanPosition(forStoragePosition: storageCursor)
            let nsClean = cleanText as NSString
            let safeCleanCursor = min(cleanCursor, max(0, nsClean.length - 1))
            let paragraphRange = nsClean.paragraphRange(for: NSRange(location: safeCleanCursor, length: 0))
            let paragraphText = nsClean.substring(with: paragraphRange)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !paragraphText.isEmpty else { return }

            parent.aiCommentManager.fetchProvocation(for: paragraphText, anchorRange: paragraphRange)
        }

        private func triggerCoachPass() {
            let cleanText = parent.text
            guard !cleanText.isEmpty else { return }
            parent.aiCommentManager.fetchCoachPass(for: cleanText)
        }

        // MARK: - Formatting

        func applyFormatting() {
            guard !isFormatting, let textView = textView else { return }
            isFormatting = true
            defer { isFormatting = false }

            let text = textView.string
            let selectedRanges = textView.selectedRanges

            textView.textStorage?.beginEditing()
            parent.formatter.format(textStorage: textView.textStorage!, text: text)
            textView.textStorage?.endEditing()

            textView.selectedRanges = selectedRanges
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            guard !isModifyingComments else { return }

            // Always propagate the *clean* text so saves never include comment blocks
            let cleanText = extractCleanText()
            parent.text = cleanText
            parent.onTextChange(cleanText)

            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                self.applyFormatting()
            }
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            // Handle AI comment dismiss links
            if let urlString = link as? String {
                if urlString.hasPrefix("warmmarkdown://dismiss/") {
                    let uuidString = String(urlString.dropFirst("warmmarkdown://dismiss/".count))
                    if let id = UUID(uuidString: uuidString) {
                        parent.aiCommentManager.dismiss(id)
                    }
                    return true
                }
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                    return true
                }
            }
            return false
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Escape → dismiss the most recent AI comment
            if commandSelector == NSSelectorFromString("cancelOperation:") {
                if !parent.aiCommentManager.activeComments.isEmpty {
                    parent.aiCommentManager.dismissMostRecent()
                    return true
                }
            }
            // Cmd+Shift+T → toggle task state
            if let event = NSApp.currentEvent,
               event.modifierFlags.contains([.command, .shift]),
               event.charactersIgnoringModifiers == "t" {
                toggleTaskAtCursor()
                return true
            }
            return false
        }

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let textStorage = textView.textStorage else { return true }
            // Prevent deletions that would consume AI comment characters
            guard affectedCharRange.length > 0 else { return true }
            let end = min(affectedCharRange.location + affectedCharRange.length, textStorage.length)
            for pos in affectedCharRange.location..<end {
                if textStorage.attribute(.aiCommentID, at: pos, effectiveRange: nil) != nil {
                    return false
                }
            }
            return true
        }

        // MARK: - Task toggle

        private func toggleTaskAtCursor() {
            guard let textView = textView else { return }
            let cursorPosition = textView.selectedRange().location
            let text = textView.string as NSString

            let lineRange = text.lineRange(for: NSRange(location: cursorPosition, length: 0))
            let line = text.substring(with: lineRange)

            if let newLine = TaskManager.shared.toggleTaskState(in: line) {
                textView.textStorage?.replaceCharacters(in: lineRange, with: newLine)
                let cleanText = extractCleanText()
                parent.text = cleanText
                parent.onTextChange(cleanText)
                applyFormatting()
            }
        }
    }
}

// MARK: - NSFont helper

private extension NSFont {
    func with(traits: NSFontDescriptor.SymbolicTraits) -> NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}

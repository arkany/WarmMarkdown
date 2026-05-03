import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct TextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    var formatter: MarkdownFormatter
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
        context.coordinator.applyFormatting()
        context.coordinator.registerNotifications()

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        context.coordinator.parent = self

        let currentText = textView.string
        if currentText != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            context.coordinator.applyFormatting()
            textView.selectedRanges = selectedRanges
        }

        textView.backgroundColor = formatter.theme.background
        scrollView.backgroundColor = formatter.theme.background
        textView.insertionPointColor = formatter.theme.accentColor
    }

    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: TextViewWrapper
        weak var textView: NSTextView?
        private var isFormatting = false
        private var imageOverlayViews: [NSView] = []
        private var imageCache: [String: NSImage] = [:]

        init(_ parent: TextViewWrapper) {
            self.parent = parent
            super.init()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        func registerNotifications() {
            let nc = NotificationCenter.default
            nc.addObserver(self, selector: #selector(handleBold), name: .editorBold, object: nil)
            nc.addObserver(self, selector: #selector(handleItalic), name: .editorItalic, object: nil)
            nc.addObserver(self, selector: #selector(handleLink), name: .editorLink, object: nil)
            nc.addObserver(self, selector: #selector(handleChecklist), name: .editorChecklist, object: nil)
            nc.addObserver(self, selector: #selector(handleImage), name: .editorImage, object: nil)
        }

        // MARK: - Formatting Actions

        @objc private func handleBold() {
            wrapSelection(prefix: "**", suffix: "**", placeholder: "bold text")
        }

        @objc private func handleItalic() {
            wrapSelection(prefix: "*", suffix: "*", placeholder: "italic text")
        }

        @objc private func handleLink() {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            let selectedText = (textView.string as NSString).substring(with: range)

            if selectedText.isEmpty {
                insertText("[link text](url)", selectRange: NSRange(location: range.location + 1, length: 9))
            } else {
                let replacement = "[\(selectedText)](url)"
                replaceAndSelect(in: range, with: replacement,
                                 selectRange: NSRange(location: range.location + selectedText.count + 3, length: 3))
            }
        }

        @objc private func handleChecklist() {
            guard let textView = textView else { return }
            let text = textView.string as NSString
            let range = textView.selectedRange()
            let lineRange = text.lineRange(for: range)
            let line = text.substring(with: lineRange)

            // If line already has a task marker, toggle its state
            if TaskManager.shared.detectTask(in: line) != nil {
                toggleTaskAtCursor()
                return
            }

            // Otherwise, insert a new task marker at the start of the line
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let newLine: String
            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                // Already a list item — insert checkbox after the marker
                let marker = String(trimmed.prefix(2))
                let rest = String(trimmed.dropFirst(2))
                newLine = "\(marker)[ ] \(rest)\n"
            } else if trimmed.isEmpty {
                newLine = "- [ ] \n"
            } else {
                newLine = "- [ ] \(trimmed)\n"
            }

            textView.textStorage?.replaceCharacters(in: lineRange, with: newLine)
            syncTextAndFormat()
            // Place cursor at end of the new line (before newline)
            textView.setSelectedRange(NSRange(location: lineRange.location + newLine.count - 1, length: 0))
        }

        @objc private func handleImage() {
            guard let textView = textView else { return }

            let panel = NSOpenPanel()
            panel.allowedContentTypes = [.image]
            panel.allowsMultipleSelection = false
            panel.message = "Choose an image to insert"

            guard panel.runModal() == .OK, let sourceURL = panel.url else { return }

            let imagePath = sourceURL.path
            let range = textView.selectedRange()
            let selectedText = (textView.string as NSString).substring(with: range)
            let altText = selectedText.isEmpty ? sourceURL.deletingPathExtension().lastPathComponent : selectedText
            let markdown = "![\(altText)](\(imagePath))"

            insertText(markdown, selectRange: NSRange(location: range.location + 2, length: altText.count))
        }

        // MARK: - Helpers

        private func wrapSelection(prefix: String, suffix: String, placeholder: String) {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            let selectedText = (textView.string as NSString).substring(with: range)

            if selectedText.isEmpty {
                // No selection: insert with placeholder selected
                let insertion = "\(prefix)\(placeholder)\(suffix)"
                let selectRange = NSRange(location: range.location + prefix.count, length: placeholder.count)
                insertText(insertion, selectRange: selectRange)
            } else {
                // Wrap existing selection — check if already wrapped and toggle off
                let nsText = textView.string as NSString
                let prefixLen = prefix.count
                let suffixLen = suffix.count

                let beforeStart = range.location - prefixLen
                let afterEnd = range.location + range.length

                if beforeStart >= 0 && afterEnd + suffixLen <= nsText.length {
                    let before = nsText.substring(with: NSRange(location: beforeStart, length: prefixLen))
                    let after = nsText.substring(with: NSRange(location: afterEnd, length: suffixLen))
                    if before == prefix && after == suffix {
                        // Already wrapped — unwrap
                        let fullRange = NSRange(location: beforeStart, length: range.length + prefixLen + suffixLen)
                        replaceAndSelect(in: fullRange, with: selectedText,
                                         selectRange: NSRange(location: beforeStart, length: selectedText.count))
                        return
                    }
                }

                let replacement = "\(prefix)\(selectedText)\(suffix)"
                replaceAndSelect(in: range, with: replacement,
                                 selectRange: NSRange(location: range.location + prefixLen, length: selectedText.count))
            }
        }

        private func insertText(_ text: String, selectRange: NSRange) {
            guard let textView = textView else { return }
            let range = textView.selectedRange()
            textView.textStorage?.replaceCharacters(in: range, with: text)
            syncTextAndFormat()
            textView.setSelectedRange(selectRange)
        }

        private func replaceAndSelect(in range: NSRange, with text: String, selectRange: NSRange) {
            guard let textView = textView else { return }
            textView.textStorage?.replaceCharacters(in: range, with: text)
            syncTextAndFormat()
            textView.setSelectedRange(selectRange)
        }

        private func syncTextAndFormat() {
            guard let textView = textView else { return }
            parent.text = textView.string
            parent.onTextChange(textView.string)
            applyFormatting()
        }

        // MARK: - NSTextViewDelegate

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string

            parent.text = newText
            parent.onTextChange(newText)

            // Apply formatting synchronously so the displayed style always
            // matches the markdown content — no flash of wrong font/size.
            applyFormatting()
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let urlString = link as? String, let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
                return true
            }
            return false
        }

        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Cmd+Shift+T to toggle task state
            if let event = NSApp.currentEvent,
               event.modifierFlags.contains([.command, .shift]),
               event.charactersIgnoringModifiers == "t" {
                toggleTaskAtCursor()
                return true
            }
            return false
        }

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
            updateImageOverlays()
        }

        // MARK: - Image overlays

        private func updateImageOverlays() {
            guard let textView = textView,
                  let layoutManager = textView.layoutManager,
                  let textContainer = textView.textContainer else { return }

            imageOverlayViews.forEach { $0.removeFromSuperview() }
            imageOverlayViews.removeAll()

            let text = textView.string as NSString
            let tokens = MarkdownParser().parse(textView.string)
            let inset = textView.textContainerInset
            layoutManager.ensureLayout(for: textContainer)

            for token in tokens {
                guard case .image(let urlString) = token.type,
                      token.range.location + token.range.length <= text.length,
                      let image = loadImage(from: urlString) else { continue }

                let glyphRange = layoutManager.glyphRange(forCharacterRange: token.range, actualCharacterRange: nil)
                var lineRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
                lineRect.origin.x += inset.width
                lineRect.origin.y += inset.height

                let maxWidth = textView.frame.width - inset.width * 2 - 32
                let aspect = image.size.width / max(image.size.height, 1)
                let displayH = min(200, image.size.height, maxWidth / max(aspect, 0.01))
                let displayW = min(maxWidth, displayH * aspect)

                let imageRect = NSRect(x: lineRect.minX, y: lineRect.maxY + 8,
                                       width: displayW, height: displayH)
                let iv = NSImageView(frame: imageRect)
                iv.image = image
                iv.imageScaling = .scaleProportionallyUpOrDown
                iv.imageAlignment = .alignTopLeft
                iv.wantsLayer = true
                iv.layer?.cornerRadius = 6
                iv.layer?.masksToBounds = true

                textView.addSubview(iv)
                imageOverlayViews.append(iv)
            }
        }

        private func loadImage(from urlString: String) -> NSImage? {
            if let cached = imageCache[urlString] { return cached }
            let image: NSImage?
            if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
                image = URL(string: urlString).flatMap { NSImage(contentsOf: $0) }
            } else {
                image = NSImage(contentsOf: URL(fileURLWithPath: urlString))
            }
            if let image { imageCache[urlString] = image }
            return image
        }

        private func toggleTaskAtCursor() {
            guard let textView = textView else { return }
            let cursorPosition = textView.selectedRange().location
            let text = textView.string as NSString

            let lineRange = text.lineRange(for: NSRange(location: cursorPosition, length: 0))
            let line = text.substring(with: lineRange)

            if let newLine = TaskManager.shared.toggleTaskState(in: line) {
                textView.textStorage?.replaceCharacters(in: lineRange, with: newLine)
                parent.text = textView.string
                parent.onTextChange(textView.string)
                applyFormatting()
            }
        }
    }
}

import SwiftUI
import AppKit

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
        textView.textContainerInset = NSSize(width: 40, height: 30)
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
        textView.insertionPointColor = formatter.theme.foreground
    }

    class Coordinator: NSObject, NSTextViewDelegate, NSTextStorageDelegate {
        var parent: TextViewWrapper
        weak var textView: NSTextView?
        private var isFormatting = false
        private var debounceTask: Task<Void, Never>?

        init(_ parent: TextViewWrapper) {
            self.parent = parent
            super.init()
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newText = textView.string

            parent.text = newText
            parent.onTextChange(newText)

            debounceTask?.cancel()
            debounceTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                self.applyFormatting()
            }
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

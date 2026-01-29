import AppKit

/// Applies NSAttributedString attributes to NSTextStorage based on parsed markdown tokens and the current theme.
/// Implements Bear-style formatting: faded syntax markers, styled content, code backgrounds.
final class MarkdownFormatter {
    let theme: MarkdownTheme
    private let parser = MarkdownParser()

    // Fonts
    private let bodyFont: NSFont
    private let monoFont: NSFont
    private let boldFont: NSFont
    private let italicFont: NSFont
    private let boldItalicFont: NSFont

    init(theme: MarkdownTheme) {
        self.theme = theme

        let size: CGFloat = 15
        self.bodyFont = NSFont.systemFont(ofSize: size)
        self.monoFont = NSFont.monospacedSystemFont(ofSize: size - 1, weight: .regular)
        self.boldFont = NSFont.boldSystemFont(ofSize: size)
        self.italicFont = {
            let descriptor = NSFont.systemFont(ofSize: size).fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? NSFont.systemFont(ofSize: size)
        }()
        self.boldItalicFont = {
            let descriptor = NSFont.boldSystemFont(ofSize: size).fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? NSFont.boldSystemFont(ofSize: size)
        }()
    }

    func format(textStorage: NSTextStorage, text: String) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }

        // Reset to base style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.paragraphSpacing = 8

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: theme.foreground,
            .paragraphStyle: paragraphStyle
        ]
        textStorage.setAttributes(baseAttributes, range: fullRange)

        // Parse and apply tokens
        let tokens = parser.parse(text)

        for token in tokens {
            // Validate range
            guard token.range.location >= 0,
                  token.range.location + token.range.length <= textStorage.length else { continue }

            switch token.type {
            case .heading(let level):
                let fontSize: CGFloat = switch level {
                case 1: 28
                case 2: 24
                case 3: 20
                case 4: 18
                case 5: 16
                default: 15
                }
                let font = NSFont.systemFont(ofSize: fontSize, weight: .bold)
                let headingParagraph = NSMutableParagraphStyle()
                headingParagraph.lineSpacing = 4
                headingParagraph.paragraphSpacingBefore = level == 1 ? 16 : 12
                headingParagraph.paragraphSpacing = 8

                textStorage.addAttributes([
                    .font: font,
                    .foregroundColor: theme.headingColor,
                    .paragraphStyle: headingParagraph,
                ], range: token.range)

            case .headingMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.headingColor.withAlphaComponent(0.3),
                ], range: token.range)

            case .bold:
                textStorage.addAttributes([
                    .font: boldFont,
                    .foregroundColor: theme.strongColor,
                ], range: token.range)

            case .boldMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.25),
                    .font: bodyFont,
                ], range: token.range)

            case .italic:
                textStorage.addAttributes([
                    .font: italicFont,
                    .foregroundColor: theme.emphasisColor,
                ], range: token.range)

            case .italicMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.25),
                    .font: bodyFont,
                ], range: token.range)

            case .boldItalic:
                textStorage.addAttributes([
                    .font: boldItalicFont,
                    .foregroundColor: theme.strongColor,
                ], range: token.range)

            case .boldItalicMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.25),
                ], range: token.range)

            case .strikethrough:
                textStorage.addAttributes([
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: theme.foreground.withAlphaComponent(0.6),
                ], range: token.range)

            case .strikethroughMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                ], range: token.range)

            case .inlineCode:
                textStorage.addAttributes([
                    .font: monoFont,
                    .foregroundColor: theme.codeForeground,
                    .backgroundColor: theme.codeBackground,
                ], range: token.range)

            case .inlineCodeMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                    .font: monoFont,
                    .backgroundColor: theme.codeBackground,
                ], range: token.range)

            case .codeBlockFence:
                textStorage.addAttributes([
                    .font: monoFont,
                    .foregroundColor: theme.commentColor,
                    .backgroundColor: theme.codeBackground,
                ], range: token.range)

            case .codeBlockContent:
                let codeParagraph = NSMutableParagraphStyle()
                codeParagraph.lineSpacing = 2
                codeParagraph.headIndent = 12
                codeParagraph.firstLineHeadIndent = 12
                codeParagraph.tailIndent = -12

                textStorage.addAttributes([
                    .font: monoFont,
                    .foregroundColor: theme.codeForeground,
                    .backgroundColor: theme.codeBackground,
                    .paragraphStyle: codeParagraph,
                ], range: token.range)

            case .link(let url):
                // We apply link attribute for the clickable portion
                _ = url // used via linkText below

            case .linkText:
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                ], range: token.range)

            case .linkURL:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                    .font: NSFont.systemFont(ofSize: 12),
                ], range: token.range)

            case .linkMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                ], range: token.range)

            case .image:
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                ], range: token.range)

            case .blockquote:
                let bqParagraph = NSMutableParagraphStyle()
                bqParagraph.lineSpacing = 4
                bqParagraph.headIndent = 20
                bqParagraph.firstLineHeadIndent = 20
                bqParagraph.paragraphSpacing = 4

                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.7),
                    .font: italicFont,
                    .paragraphStyle: bqParagraph,
                ], range: token.range)

            case .blockquoteMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.blockquoteBorder,
                ], range: token.range)

            case .listMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.listMarkerColor,
                    .font: NSFont.systemFont(ofSize: 15, weight: .semibold),
                ], range: token.range)

            case .horizontalRule:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                ], range: token.range)

            case .taskTodo:
                textStorage.addAttributes([
                    .foregroundColor: theme.commentColor,
                ], range: token.range)

            case .taskDone:
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                ], range: token.range)

            case .taskInProgress:
                textStorage.addAttributes([
                    .foregroundColor: theme.headingColor,
                ], range: token.range)

            case .taskBlocked:
                textStorage.addAttributes([
                    .foregroundColor: NSColor.systemRed,
                ], range: token.range)

            case .wikiLink(let target):
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .link: "wikilink://\(target)",
                ], range: token.range)

            case .wikiLinkMarker:
                textStorage.addAttributes([
                    .foregroundColor: theme.foreground.withAlphaComponent(0.2),
                ], range: token.range)

            case .tag:
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                    .font: NSFont.systemFont(ofSize: 14, weight: .medium),
                ], range: token.range)
            }
        }
    }
}

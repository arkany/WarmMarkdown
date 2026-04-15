import AppKit

/// Applies NSAttributedString attributes to NSTextStorage based on parsed markdown tokens and the current theme.
/// Implements Bear-style formatting: faded syntax markers, styled content, code backgrounds.
final class MarkdownFormatter {
    let theme: MarkdownTheme
    private let parser = MarkdownParser()

    // Fonts — serif body to match reference design
    private let bodyFont: NSFont
    private let monoFont: NSFont
    private let boldFont: NSFont
    private let italicFont: NSFont
    private let boldItalicFont: NSFont

    init(theme: MarkdownTheme) {
        self.theme = theme

        let size: CGFloat = 16

        // Use a serif font for body (matching Newsreader from reference)
        let serifFont = NSFont(name: "Georgia", size: size) ?? NSFont.systemFont(ofSize: size)
        let serifBold = NSFont(name: "Georgia-Bold", size: size) ?? NSFont.boldSystemFont(ofSize: size)
        let serifItalic = NSFont(name: "Georgia-Italic", size: size) ?? {
            let descriptor = serifFont.fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? serifFont
        }()
        let serifBoldItalic = NSFont(name: "Georgia-BoldItalic", size: size) ?? {
            let descriptor = serifBold.fontDescriptor.withSymbolicTraits(.italic)
            return NSFont(descriptor: descriptor, size: size) ?? serifBold
        }()

        self.bodyFont = serifFont
        self.monoFont = NSFont.monospacedSystemFont(ofSize: size - 2, weight: .regular)
        self.boldFont = serifBold
        self.italicFont = serifItalic
        self.boldItalicFont = serifBoldItalic
    }

    func format(textStorage: NSTextStorage, text: String) {
        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }

        // Save AI comment ranges before the full reset — setAttributes below wipes everything.
        // Each entry is (storageRange, fullAttributeDict) so we can restore exactly.
        var savedCommentRanges: [(NSRange, [NSAttributedString.Key: Any])] = []
        var scanPos = 0
        while scanPos < textStorage.length {
            var effectiveRange = NSRange()
            if textStorage.attribute(.aiCommentID, at: scanPos, effectiveRange: &effectiveRange) != nil {
                let attrs = textStorage.attributes(at: scanPos, effectiveRange: nil)
                savedCommentRanges.append((effectiveRange, attrs))
                scanPos = effectiveRange.location + effectiveRange.length
            } else {
                scanPos += 1
            }
        }

        // Reset to base style — generous line spacing matching reference's leading-loose
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 8
        paragraphStyle.paragraphSpacing = 12

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
                case 1: 36
                case 2: 28
                case 3: 22
                case 4: 18
                case 5: 16
                default: 15
                }
                // Use serif font for headings to match reference
                let headingFont = NSFont(name: "Georgia-Bold", size: fontSize)
                    ?? NSFont.systemFont(ofSize: fontSize, weight: .bold)
                let headingParagraph = NSMutableParagraphStyle()
                headingParagraph.lineSpacing = 4
                headingParagraph.paragraphSpacingBefore = level == 1 ? 20 : 14
                headingParagraph.paragraphSpacing = 10

                textStorage.addAttributes([
                    .font: headingFont,
                    .foregroundColor: theme.headingColor,
                    .paragraphStyle: headingParagraph,
                    .kern: -0.5,
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
                // Style the entire ![alt](url) as a link-coloured image reference
                textStorage.addAttributes([
                    .foregroundColor: theme.linkColor,
                    .font: bodyFont,
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

        // Restore AI comment ranges — overrides any token attributes applied above.
        for (range, attrs) in savedCommentRanges {
            guard range.location + range.length <= textStorage.length else { continue }
            textStorage.setAttributes(attrs, range: range)
        }
    }
}

import Foundation

/// Lightweight markdown token parser producing ranges for formatting.
/// Uses regex-based parsing for real-time formatting in the editor.
/// swift-markdown is used for full document parsing when needed.
struct MarkdownParser {

    enum TokenType {
        case heading(level: Int)
        case headingMarker(level: Int)
        case bold
        case boldMarker
        case italic
        case italicMarker
        case boldItalic
        case boldItalicMarker
        case inlineCode
        case inlineCodeMarker
        case codeBlockFence
        case codeBlockContent
        case link(url: String)
        case linkText
        case linkURL
        case linkMarker
        case image
        case blockquote
        case blockquoteMarker
        case listMarker
        case horizontalRule
        case strikethrough
        case strikethroughMarker
        case taskTodo
        case taskDone
        case taskInProgress
        case taskBlocked
        case wikiLink(target: String)
        case wikiLinkMarker
        case tag(name: String)
    }

    struct Token {
        let type: TokenType
        let range: NSRange
    }

    func parse(_ text: String) -> [Token] {
        var tokens: [Token] = []
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        // Process line-by-line for block-level elements
        var inCodeBlock = false

        nsText.enumerateSubstrings(in: fullRange, options: .byLines) { line, lineRange, _, _ in
            guard let line = line else { return }

            if line.hasPrefix("```") {
                tokens.append(Token(type: .codeBlockFence, range: lineRange))
                inCodeBlock = !inCodeBlock
                return
            }

            if inCodeBlock {
                tokens.append(Token(type: .codeBlockContent, range: lineRange))
                return
            }

            // Headings
            let headingPattern = #"^(#{1,6})\s+"#
            if let regex = try? NSRegularExpression(pattern: headingPattern),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
                let level = match.range(at: 1).length
                let markerRange = NSRange(location: lineRange.location, length: match.range.length)
                let contentRange = NSRange(location: lineRange.location, length: lineRange.length)
                tokens.append(Token(type: .headingMarker(level: level), range: markerRange))
                tokens.append(Token(type: .heading(level: level), range: contentRange))
            }

            // Blockquotes
            if line.hasPrefix("> ") || line == ">" {
                let markerRange = NSRange(location: lineRange.location, length: min(2, lineRange.length))
                tokens.append(Token(type: .blockquoteMarker, range: markerRange))
                tokens.append(Token(type: .blockquote, range: lineRange))
            }

            // Horizontal rules
            let hrTrimmed = line.trimmingCharacters(in: .whitespaces)
            if hrTrimmed.count >= 3 && (hrTrimmed.allSatisfy({ $0 == "-" }) || hrTrimmed.allSatisfy({ $0 == "*" }) || hrTrimmed.allSatisfy({ $0 == "_" })) {
                tokens.append(Token(type: .horizontalRule, range: lineRange))
                return
            }

            // List markers
            let listPattern = #"^(\s*)([-*+]|\d+\.)\s"#
            if let regex = try? NSRegularExpression(pattern: listPattern),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
                let markerNSRange = match.range(at: 2)
                let markerRange = NSRange(location: lineRange.location + markerNSRange.location, length: markerNSRange.length)
                tokens.append(Token(type: .listMarker, range: markerRange))
            }

            // Task items
            let taskPattern = #"^(\s*[-*+]\s)\[([ x/\-])\]"#
            if let regex = try? NSRegularExpression(pattern: taskPattern),
               let match = regex.firstMatch(in: line, range: NSRange(location: 0, length: line.count)) {
                let stateRange = match.range(at: 2)
                if let r = Range(stateRange, in: line) {
                    let state = String(line[r])
                    let tokenRange = NSRange(location: lineRange.location + match.range.location, length: match.range.length + 1) // include ]
                    switch state {
                    case " ": tokens.append(Token(type: .taskTodo, range: tokenRange))
                    case "x": tokens.append(Token(type: .taskDone, range: tokenRange))
                    case "/": tokens.append(Token(type: .taskInProgress, range: tokenRange))
                    case "-": tokens.append(Token(type: .taskBlocked, range: tokenRange))
                    default: break
                    }
                }
            }

            // Inline elements
            self.parseInlineTokens(line: line, lineOffset: lineRange.location, tokens: &tokens)
        }

        return tokens
    }

    private func parseInlineTokens(line: String, lineOffset: Int, tokens: inout [Token]) {
        let nsLine = line as NSString

        // Bold+Italic ***text***
        parsePattern(#"\*{3}(.+?)\*{3}"#, in: nsLine, offset: lineOffset, markerLen: 3,
                     contentType: .boldItalic, markerType: .boldItalicMarker, tokens: &tokens)

        // Bold **text**
        parsePattern(#"\*{2}(.+?)\*{2}"#, in: nsLine, offset: lineOffset, markerLen: 2,
                     contentType: .bold, markerType: .boldMarker, tokens: &tokens)

        // Italic *text*  (not preceded or followed by *)
        parsePattern(#"(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)"#, in: nsLine, offset: lineOffset, markerLen: 1,
                     contentType: .italic, markerType: .italicMarker, tokens: &tokens)

        // Strikethrough ~~text~~
        parsePattern(#"~~(.+?)~~"#, in: nsLine, offset: lineOffset, markerLen: 2,
                     contentType: .strikethrough, markerType: .strikethroughMarker, tokens: &tokens)

        // Inline code `text`
        parsePattern(#"`([^`]+)`"#, in: nsLine, offset: lineOffset, markerLen: 1,
                     contentType: .inlineCode, markerType: .inlineCodeMarker, tokens: &tokens)

        // Images ![alt](url) — must be parsed before links to avoid partial overlap
        let imagePattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        var imageCoveredRanges: [NSRange] = []
        if let regex = try? NSRegularExpression(pattern: imagePattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let fullRange = NSRange(location: lineOffset + match.range.location, length: match.range.length)
                let altRange = match.range(at: 1)
                let urlRange = match.range(at: 2)

                if let r = Range(urlRange, in: line) {
                    let url = String(line[r])
                    tokens.append(Token(type: .image, range: fullRange))
                    // Alt text
                    if altRange.length > 0 {
                        tokens.append(Token(type: .linkText, range: NSRange(location: lineOffset + altRange.location, length: altRange.length)))
                    }
                    // URL portion (faded)
                    tokens.append(Token(type: .linkURL, range: NSRange(location: lineOffset + urlRange.location, length: urlRange.length)))
                    // Markers: ![ ]( and )
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + match.range.location, length: 2))) // ![
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + altRange.location + altRange.length, length: 2))) // ](
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + match.range.location + match.range.length - 1, length: 1))) // )
                    imageCoveredRanges.append(match.range)
                }
            }
        }

        // Links [text](url) — skip ranges already covered by images
        let linkPattern = #"\[([^\]]+)\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: linkPattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                // Skip if this match is inside an image token
                let overlaps = imageCoveredRanges.contains { imageRange in
                    NSIntersectionRange(imageRange, match.range).length > 0
                }
                guard !overlaps else { continue }

                let fullRange = NSRange(location: lineOffset + match.range.location, length: match.range.length)
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)

                if let r = Range(urlRange, in: line) {
                    let url = String(line[r])
                    tokens.append(Token(type: .link(url: url), range: fullRange))
                    tokens.append(Token(type: .linkText, range: NSRange(location: lineOffset + textRange.location, length: textRange.length)))

                    // Marker: [ before text
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + match.range.location, length: 1)))
                    // Marker: ]( between text and url
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + textRange.location + textRange.length, length: 2)))
                    // URL portion
                    tokens.append(Token(type: .linkURL, range: NSRange(location: lineOffset + urlRange.location, length: urlRange.length)))
                    // Marker: ) at end
                    tokens.append(Token(type: .linkMarker, range: NSRange(location: lineOffset + match.range.location + match.range.length - 1, length: 1)))
                }
            }
        }

        // Wiki-links [[target]]
        let wikiPattern = #"\[\[([^\]]+)\]\]"#
        if let regex = try? NSRegularExpression(pattern: wikiPattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let targetRange = match.range(at: 1)
                if let r = Range(targetRange, in: line) {
                    let target = String(line[r])
                    let fullRange = NSRange(location: lineOffset + match.range.location, length: match.range.length)
                    tokens.append(Token(type: .wikiLink(target: target), range: fullRange))
                    // Markers: [[ and ]]
                    tokens.append(Token(type: .wikiLinkMarker, range: NSRange(location: lineOffset + match.range.location, length: 2)))
                    tokens.append(Token(type: .wikiLinkMarker, range: NSRange(location: lineOffset + match.range.location + match.range.length - 2, length: 2)))
                }
            }
        }

        // Tags #tag
        let tagPattern = #"(?:^|\s)#([a-zA-Z][a-zA-Z0-9_-]*)"#
        if let regex = try? NSRegularExpression(pattern: tagPattern) {
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            for match in matches {
                let tagNameRange = match.range(at: 1)
                if let r = Range(tagNameRange, in: line) {
                    let tagName = String(line[r])
                    // Include the # sign
                    let hashLocation = lineOffset + tagNameRange.location - 1
                    let fullRange = NSRange(location: hashLocation, length: tagNameRange.length + 1)
                    tokens.append(Token(type: .tag(name: tagName), range: fullRange))
                }
            }
        }
    }

    private func parsePattern(_ pattern: String, in nsLine: NSString, offset: Int, markerLen: Int,
                              contentType: TokenType, markerType: TokenType, tokens: inout [Token]) {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let matches = regex.matches(in: nsLine as String, range: NSRange(location: 0, length: nsLine.length))
        for match in matches {
            let contentRange = match.range(at: 1)
            // Content
            tokens.append(Token(type: contentType, range: NSRange(location: offset + contentRange.location, length: contentRange.length)))
            // Opening marker
            tokens.append(Token(type: markerType, range: NSRange(location: offset + match.range.location, length: markerLen)))
            // Closing marker
            tokens.append(Token(type: markerType, range: NSRange(location: offset + match.range.location + match.range.length - markerLen, length: markerLen)))
        }
    }
}

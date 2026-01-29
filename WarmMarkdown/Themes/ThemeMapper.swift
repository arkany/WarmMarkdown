import AppKit

/// Maps VSCode theme JSON → MarkdownTheme
enum ThemeMapper {
    static func map(from vscodeTheme: VSCodeThemeFile, id: String, name: String) -> MarkdownTheme {
        let isDark = vscodeTheme.type == "dark"
        let defaultBg = isDark ? "#1E1E1E" : "#FFFFFF"
        let defaultFg = isDark ? "#D4D4D4" : "#333333"

        let bg = vscodeTheme.editorColor("editor.background") ?? defaultBg
        let fg = vscodeTheme.editorColor("editor.foreground") ?? defaultFg

        // Heading: keyword scope
        let heading = vscodeTheme.colorForScope("keyword")
            ?? vscodeTheme.colorForScope("markup.heading")
            ?? vscodeTheme.colorForScope("entity.name")
            ?? (isDark ? "#569CD6" : "#0000FF")

        // Link: string scope
        let link = vscodeTheme.colorForScope("string")
            ?? vscodeTheme.colorForScope("markup.underline.link")
            ?? (isDark ? "#CE9178" : "#008000")

        // Code background: comment scope or lineHighlight
        let codeBg = vscodeTheme.editorColor("editor.lineHighlightBackground")
            ?? vscodeTheme.colorForScope("comment").flatMap { adjustAlpha($0, alpha: 0.15, on: bg) }
            ?? (isDark ? "#2D2D2D" : "#F5F5F5")

        // Code foreground
        let codeFg = vscodeTheme.colorForScope("string.quoted")
            ?? vscodeTheme.colorForScope("variable")
            ?? fg

        // Selection
        let selection = vscodeTheme.editorColor("editor.selectionBackground")
            ?? (isDark ? "#264F78" : "#ADD6FF")

        // Comment color
        let comment = vscodeTheme.colorForScope("comment")
            ?? (isDark ? "#6A9955" : "#008000")

        // Strong/emphasis
        let strong = vscodeTheme.colorForScope("markup.bold") ?? fg
        let emphasis = vscodeTheme.colorForScope("markup.italic")
            ?? vscodeTheme.colorForScope("variable")
            ?? fg

        // Blockquote border
        let blockquoteBorder = vscodeTheme.editorColor("editorIndentGuide.activeBackground")
            ?? comment

        // List marker
        let listMarker = vscodeTheme.colorForScope("keyword.operator")
            ?? heading

        return MarkdownTheme(
            id: id,
            name: name,
            background: NSColor(hex: bg),
            foreground: NSColor(hex: fg),
            headingColor: NSColor(hex: heading),
            linkColor: NSColor(hex: link),
            codeBackground: NSColor(hex: codeBg),
            codeForeground: NSColor(hex: codeFg),
            selectionColor: NSColor(hex: selection),
            commentColor: NSColor(hex: comment),
            strongColor: NSColor(hex: strong),
            emphasisColor: NSColor(hex: emphasis),
            blockquoteBorder: NSColor(hex: blockquoteBorder),
            listMarkerColor: NSColor(hex: listMarker),
            isDark: isDark
        )
    }

    /// Blend a hex color at the given alpha onto a background
    private static func adjustAlpha(_ hexColor: String, alpha: CGFloat, on bgHex: String) -> String {
        let fg = NSColor(hex: hexColor)
        let bg = NSColor(hex: bgHex)

        guard let fgRGB = fg.usingColorSpace(.sRGB),
              let bgRGB = bg.usingColorSpace(.sRGB) else { return hexColor }

        let r = fgRGB.redComponent * alpha + bgRGB.redComponent * (1 - alpha)
        let g = fgRGB.greenComponent * alpha + bgRGB.greenComponent * (1 - alpha)
        let b = fgRGB.blueComponent * alpha + bgRGB.blueComponent * (1 - alpha)

        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

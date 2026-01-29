import SwiftUI
import AppKit

struct MarkdownTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let background: NSColor
    let foreground: NSColor
    let headingColor: NSColor
    let linkColor: NSColor
    let codeBackground: NSColor
    let codeForeground: NSColor
    let selectionColor: NSColor
    let commentColor: NSColor
    let strongColor: NSColor
    let emphasisColor: NSColor
    let blockquoteBorder: NSColor
    let listMarkerColor: NSColor
    let isDark: Bool

    /// Default warm oatmeal theme
    static let warmOatmeal = MarkdownTheme(
        id: "warm-oatmeal",
        name: "Warm Oatmeal",
        background: NSColor(hex: "#FAF6F0"),
        foreground: NSColor(hex: "#3C3836"),
        headingColor: NSColor(hex: "#9D4E3A"),
        linkColor: NSColor(hex: "#6A8B6D"),
        codeBackground: NSColor(hex: "#F0EBE3"),
        codeForeground: NSColor(hex: "#7C6F64"),
        selectionColor: NSColor(hex: "#D5CCB4"),
        commentColor: NSColor(hex: "#A89984"),
        strongColor: NSColor(hex: "#3C3836"),
        emphasisColor: NSColor(hex: "#5C5350"),
        blockquoteBorder: NSColor(hex: "#D5CCB4"),
        listMarkerColor: NSColor(hex: "#9D4E3A"),
        isDark: false
    )
}

extension NSColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let length = hexSanitized.count
        if length == 8 {
            let r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: a)
        } else {
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b, alpha: 1.0)
        }
    }

    var hexString: String {
        guard let rgbColor = usingColorSpace(.sRGB) else { return "#000000" }
        let r = Int(rgbColor.redComponent * 255)
        let g = Int(rgbColor.greenComponent * 255)
        let b = Int(rgbColor.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

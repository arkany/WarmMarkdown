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

    // UI chrome colors (sidebar, toolbar, AI pane)
    let sidebarBackground: NSColor
    let sidebarBorder: NSColor
    let sidebarItemActive: NSColor
    let sidebarItemHover: NSColor
    let sidebarTextPrimary: NSColor
    let sidebarTextSecondary: NSColor
    let sidebarTextMuted: NSColor
    let accentColor: NSColor
    let toolbarDivider: NSColor
    let aiPaneBackground: NSColor
    let aiPaneBorder: NSColor
    let aiBubbleBackground: NSColor
    let userBubbleBackground: NSColor
    let inputBorder: NSColor
    let floatingToolbarBackground: NSColor
    let searchBackground: NSColor
    let searchFocusBackground: NSColor
    let searchFocusBorder: NSColor
    let tagTextColor: NSColor
    let tagHashColor: NSColor

    /// Default warm oatmeal theme — matched to generated-page-8.html
    static let warmOatmeal = MarkdownTheme(
        id: "warm-oatmeal",
        name: "Warm Oatmeal",
        background: NSColor(hex: "#F9F7F1"),
        foreground: NSColor(hex: "#383838"),
        headingColor: NSColor(hex: "#1A1A1A"),
        linkColor: NSColor(hex: "#6A8B6D"),
        codeBackground: NSColor(hex: "#F0EBE3"),
        codeForeground: NSColor(hex: "#7C6F64"),
        selectionColor: NSColor(hex: "#E2DDD3"),
        commentColor: NSColor(hex: "#A89984"),
        strongColor: NSColor(hex: "#383838"),
        emphasisColor: NSColor(hex: "#555555"),
        blockquoteBorder: NSColor(hex: "#D96C48"),
        listMarkerColor: NSColor(hex: "#D96C48"),
        isDark: false,
        sidebarBackground: NSColor(hex: "#F2EFE9"),
        sidebarBorder: NSColor(hex: "#E6E1D6"),
        sidebarItemActive: NSColor(hex: "#E6E1D6"),
        sidebarItemHover: NSColor(hex: "#E8E4DC"),
        sidebarTextPrimary: NSColor(hex: "#2A2A2A"),
        sidebarTextSecondary: NSColor(hex: "#555555"),
        sidebarTextMuted: NSColor(hex: "#8C8C8C"),
        accentColor: NSColor(hex: "#D96C48"),
        toolbarDivider: NSColor(hex: "#F0EBE5"),
        aiPaneBackground: NSColor(hex: "#FFFFFF"),
        aiPaneBorder: NSColor(hex: "#E6E1D6"),
        aiBubbleBackground: NSColor(hex: "#F5F2EC"),
        userBubbleBackground: NSColor(hex: "#FFFFFF"),
        inputBorder: NSColor(hex: "#E0DCD3"),
        floatingToolbarBackground: NSColor(hex: "#2A2A2A"),
        searchBackground: NSColor(hex: "#E8E4DC"),
        searchFocusBackground: NSColor(hex: "#F9F7F1"),
        searchFocusBorder: NSColor(hex: "#D1CDC4"),
        tagTextColor: NSColor(hex: "#666666"),
        tagHashColor: NSColor(hex: "#B0ACA5")
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

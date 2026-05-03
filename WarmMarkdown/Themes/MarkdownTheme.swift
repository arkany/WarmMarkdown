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

    /// Claude — warm terracotta dark theme inspired by Claude AI's design system
    static let claude = MarkdownTheme(
        id: "claude",
        name: "Claude",
        background: NSColor(hex: "#1A1815"),
        foreground: NSColor(hex: "#E8E6E3"),
        headingColor: NSColor(hex: "#F5F0EB"),
        linkColor: NSColor(hex: "#42A5F5"),
        codeBackground: NSColor(hex: "#252118"),
        codeForeground: NSColor(hex: "#D4916A"),
        selectionColor: NSColor(hex: "#C15F3C30"),
        commentColor: NSColor(hex: "#6A6158"),
        strongColor: NSColor(hex: "#F5F0EB"),
        emphasisColor: NSColor(hex: "#D4916A"),
        blockquoteBorder: NSColor(hex: "#C15F3C"),
        listMarkerColor: NSColor(hex: "#C15F3C"),
        isDark: true,
        sidebarBackground: NSColor(hex: "#201D18"),
        sidebarBorder: NSColor(hex: "#3A352B"),
        sidebarItemActive: NSColor(hex: "#2A251D"),
        sidebarItemHover: NSColor(hex: "#2A251D"),
        sidebarTextPrimary: NSColor(hex: "#E8E6E3"),
        sidebarTextSecondary: NSColor(hex: "#B1ADA1"),
        sidebarTextMuted: NSColor(hex: "#6A6158"),
        accentColor: NSColor(hex: "#C15F3C"),
        toolbarDivider: NSColor(hex: "#3A352B"),
        aiPaneBackground: NSColor(hex: "#201D18"),
        aiPaneBorder: NSColor(hex: "#3A352B"),
        aiBubbleBackground: NSColor(hex: "#2A251D"),
        userBubbleBackground: NSColor(hex: "#1A1815"),
        inputBorder: NSColor(hex: "#3A352B"),
        floatingToolbarBackground: NSColor(hex: "#2A251D"),
        searchBackground: NSColor(hex: "#252118"),
        searchFocusBackground: NSColor(hex: "#1A1815"),
        searchFocusBorder: NSColor(hex: "#C15F3C"),
        tagTextColor: NSColor(hex: "#B1ADA1"),
        tagHashColor: NSColor(hex: "#6A6158")
    )

    /// Ayu Dark — deep blue-black with golden yellow accents
    static let ayuDark = MarkdownTheme(
        id: "ayu-dark",
        name: "Ayu Dark",
        background: NSColor(hex: "#0D1017"),
        foreground: NSColor(hex: "#BFBDB6"),
        headingColor: NSColor(hex: "#E6B450"),
        linkColor: NSColor(hex: "#59C2FF"),
        codeBackground: NSColor(hex: "#10141C"),
        codeForeground: NSColor(hex: "#AAD94C"),
        selectionColor: NSColor(hex: "#3388FF40"),
        commentColor: NSColor(hex: "#5A6673"),
        strongColor: NSColor(hex: "#E6B450"),
        emphasisColor: NSColor(hex: "#FFB454"),
        blockquoteBorder: NSColor(hex: "#FF8F40"),
        listMarkerColor: NSColor(hex: "#FF8F40"),
        isDark: true,
        sidebarBackground: NSColor(hex: "#0B0E14"),
        sidebarBorder: NSColor(hex: "#1B1F29"),
        sidebarItemActive: NSColor(hex: "#1B1F29"),
        sidebarItemHover: NSColor(hex: "#161A24"),
        sidebarTextPrimary: NSColor(hex: "#BFBDB6"),
        sidebarTextSecondary: NSColor(hex: "#8B919B"),
        sidebarTextMuted: NSColor(hex: "#5A6378"),
        accentColor: NSColor(hex: "#E6B450"),
        toolbarDivider: NSColor(hex: "#1B1F29"),
        aiPaneBackground: NSColor(hex: "#0B0E14"),
        aiPaneBorder: NSColor(hex: "#1B1F29"),
        aiBubbleBackground: NSColor(hex: "#10141C"),
        userBubbleBackground: NSColor(hex: "#0D1017"),
        inputBorder: NSColor(hex: "#5A637833"),
        floatingToolbarBackground: NSColor(hex: "#10141C"),
        searchBackground: NSColor(hex: "#161A24"),
        searchFocusBackground: NSColor(hex: "#0D1017"),
        searchFocusBorder: NSColor(hex: "#E6B450"),
        tagTextColor: NSColor(hex: "#8B919B"),
        tagHashColor: NSColor(hex: "#5A6378")
    )

    /// Vercel — minimal monochrome dark theme inspired by Vercel's design
    static let vercel = MarkdownTheme(
        id: "vercel",
        name: "Vercel",
        background: NSColor(hex: "#000000"),
        foreground: NSColor(hex: "#DCE3EA"),
        headingColor: NSColor(hex: "#FFFFFF"),
        linkColor: NSColor(hex: "#43AAF9"),
        codeBackground: NSColor(hex: "#111111"),
        codeForeground: NSColor(hex: "#62C073"),
        selectionColor: NSColor(hex: "#43AAF955"),
        commentColor: NSColor(hex: "#888888"),
        strongColor: NSColor(hex: "#FFFFFF"),
        emphasisColor: NSColor(hex: "#BF7AF0"),
        blockquoteBorder: NSColor(hex: "#F75F8F"),
        listMarkerColor: NSColor(hex: "#F75F8F"),
        isDark: true,
        sidebarBackground: NSColor(hex: "#010101"),
        sidebarBorder: NSColor(hex: "#222222"),
        sidebarItemActive: NSColor(hex: "#1A1A1A"),
        sidebarItemHover: NSColor(hex: "#141414"),
        sidebarTextPrimary: NSColor(hex: "#DCE3EA"),
        sidebarTextSecondary: NSColor(hex: "#999999"),
        sidebarTextMuted: NSColor(hex: "#454D54"),
        accentColor: NSColor(hex: "#F75F8F"),
        toolbarDivider: NSColor(hex: "#222222"),
        aiPaneBackground: NSColor(hex: "#010101"),
        aiPaneBorder: NSColor(hex: "#222222"),
        aiBubbleBackground: NSColor(hex: "#111111"),
        userBubbleBackground: NSColor(hex: "#000000"),
        inputBorder: NSColor(hex: "#34393E"),
        floatingToolbarBackground: NSColor(hex: "#111111"),
        searchBackground: NSColor(hex: "#141414"),
        searchFocusBackground: NSColor(hex: "#000000"),
        searchFocusBorder: NSColor(hex: "#F75F8F"),
        tagTextColor: NSColor(hex: "#999999"),
        tagHashColor: NSColor(hex: "#454D54")
    )

    /// Cyberdeck 2025 — retro-futuristic cyberpunk neon theme
    static let cyberdeck2025 = MarkdownTheme(
        id: "cyberdeck-2025",
        name: "Cyberdeck 2025",
        background: NSColor(hex: "#130D1A"),
        foreground: NSColor(hex: "#DED2CD"),
        headingColor: NSColor(hex: "#58C7E0"),
        linkColor: NSColor(hex: "#00FF88"),
        codeBackground: NSColor(hex: "#1A1225"),
        codeForeground: NSColor(hex: "#F9C80E"),
        selectionColor: NSColor(hex: "#46346588"),
        commentColor: NSColor(hex: "#6071CC"),
        strongColor: NSColor(hex: "#FF2289"),
        emphasisColor: NSColor(hex: "#B141F1"),
        blockquoteBorder: NSColor(hex: "#F92AAD"),
        listMarkerColor: NSColor(hex: "#F92AAD"),
        isDark: true,
        sidebarBackground: NSColor(hex: "#100C0F"),
        sidebarBorder: NSColor(hex: "#2A2139"),
        sidebarItemActive: NSColor(hex: "#2A2139"),
        sidebarItemHover: NSColor(hex: "#3C1C4E"),
        sidebarTextPrimary: NSColor(hex: "#DED2CD"),
        sidebarTextSecondary: NSColor(hex: "#B893CE"),
        sidebarTextMuted: NSColor(hex: "#6071CC"),
        accentColor: NSColor(hex: "#FF2289"),
        toolbarDivider: NSColor(hex: "#2A2139"),
        aiPaneBackground: NSColor(hex: "#100C0F"),
        aiPaneBorder: NSColor(hex: "#2A2139"),
        aiBubbleBackground: NSColor(hex: "#1A1225"),
        userBubbleBackground: NSColor(hex: "#130D1A"),
        inputBorder: NSColor(hex: "#2A2139"),
        floatingToolbarBackground: NSColor(hex: "#1A1225"),
        searchBackground: NSColor(hex: "#1A1225"),
        searchFocusBackground: NSColor(hex: "#130D1A"),
        searchFocusBorder: NSColor(hex: "#F92AAD"),
        tagTextColor: NSColor(hex: "#B893CE"),
        tagHashColor: NSColor(hex: "#6071CC")
    )

    /// All available themes
    static let allThemes: [MarkdownTheme] = [
        .warmOatmeal,
        .claude,
        .ayuDark,
        .vercel,
        .cyberdeck2025,
    ]
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

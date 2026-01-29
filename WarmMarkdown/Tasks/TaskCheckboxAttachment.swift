import AppKit

/// NSTextAttachment subclass that renders custom checkbox icons for each task state.
final class TaskCheckboxAttachment: NSTextAttachment {
    let taskState: TaskState
    private static let size = CGSize(width: 18, height: 18)

    init(state: TaskState) {
        self.taskState = state
        super.init(data: nil, ofType: nil)
        self.image = Self.renderCheckbox(for: state)
    }

    required init?(coder: NSCoder) {
        self.taskState = .todo
        super.init(coder: coder)
    }

    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: NSRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> NSRect {
        let yOffset = (lineFrag.height - Self.size.height) / 2 - 2
        return NSRect(origin: CGPoint(x: 0, y: yOffset), size: Self.size)
    }

    private static func renderCheckbox(for state: TaskState) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()

        let rect = NSRect(origin: .zero, size: size).insetBy(dx: 1, dy: 1)

        switch state {
        case .todo:
            // Empty circle
            NSColor.systemGray.withAlphaComponent(0.5).setStroke()
            let path = NSBezierPath(ovalIn: rect)
            path.lineWidth = 1.5
            path.stroke()

        case .done:
            // Filled circle with checkmark
            NSColor.systemGreen.setFill()
            NSBezierPath(ovalIn: rect).fill()

            NSColor.white.setStroke()
            let checkPath = NSBezierPath()
            checkPath.move(to: NSPoint(x: 5, y: 9))
            checkPath.line(to: NSPoint(x: 7.5, y: 6))
            checkPath.line(to: NSPoint(x: 13, y: 12.5))
            checkPath.lineWidth = 2
            checkPath.lineCapStyle = .round
            checkPath.lineJoinStyle = .round
            checkPath.stroke()

        case .inProgress:
            // Dotted circle
            NSColor.systemOrange.setStroke()
            let path = NSBezierPath(ovalIn: rect)
            path.lineWidth = 1.5
            let pattern: [CGFloat] = [3, 3]
            path.setLineDash(pattern, count: 2, phase: 0)
            path.stroke()

            // Small filled dot in center
            NSColor.systemOrange.setFill()
            let dotRect = NSRect(x: size.width / 2 - 2.5, y: size.height / 2 - 2.5, width: 5, height: 5)
            NSBezierPath(ovalIn: dotRect).fill()

        case .blocked:
            // Circle with X
            NSColor.systemRed.withAlphaComponent(0.8).setStroke()
            let circlePath = NSBezierPath(ovalIn: rect)
            circlePath.lineWidth = 1.5
            circlePath.stroke()

            let xPath = NSBezierPath()
            xPath.move(to: NSPoint(x: 5.5, y: 5.5))
            xPath.line(to: NSPoint(x: 12.5, y: 12.5))
            xPath.move(to: NSPoint(x: 12.5, y: 5.5))
            xPath.line(to: NSPoint(x: 5.5, y: 12.5))
            xPath.lineWidth = 1.5
            xPath.lineCapStyle = .round
            xPath.stroke()
        }

        image.unlockFocus()
        return image
    }
}

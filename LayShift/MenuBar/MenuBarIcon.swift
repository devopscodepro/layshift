import AppKit

// placeholder until the branded glyph is designed: a keyboard outline with a highlighted key
@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            let frame = NSRect(x: 1, y: 4, width: 16, height: 10)
            let outline = NSBezierPath(roundedRect: frame, xRadius: 2, yRadius: 2)
            outline.lineWidth = 1.5
            NSColor.black.setStroke()
            outline.stroke()

            NSColor.black.setFill()
            for row in 0..<2 {
                for column in 0..<4 {
                    let key = NSRect(x: 3.5 + CGFloat(column) * 3, y: 9.5 - CGFloat(row) * 3, width: 2, height: 2)
                    NSBezierPath(roundedRect: key, xRadius: 0.5, yRadius: 0.5).fill()
                }
            }
            NSBezierPath(roundedRect: NSRect(x: 5, y: 5.5, width: 8, height: 1.5), xRadius: 0.5, yRadius: 0.5).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "LayShift"
        return image
    }()
}

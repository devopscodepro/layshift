import AppKit

// the app icon's two keycaps as a template glyph: the back one outlined, the front one solid
@MainActor
enum MenuBarIcon {
    static let image: NSImage = {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { _ in
            let keycap = { (rect: NSRect) in NSBezierPath(roundedRect: rect, xRadius: 2.2, yRadius: 2.2) }
            let back = NSRect(x: 6.5, y: 6.5, width: 10, height: 10)
            let front = NSRect(x: 1.5, y: 1.5, width: 10, height: 10)

            NSColor.black.setStroke()
            NSColor.black.setFill()

            // only the visible part of the back keycap, so the overlap reads as depth
            NSGraphicsContext.saveGraphicsState()
            let clip = NSBezierPath(rect: NSRect(origin: .zero, size: size))
            clip.append(keycap(front.insetBy(dx: -1.2, dy: -1.2)))
            clip.windingRule = .evenOdd
            clip.addClip()
            let outline = keycap(back.insetBy(dx: 0.75, dy: 0.75))
            outline.lineWidth = 1.5
            outline.stroke()
            NSGraphicsContext.restoreGraphicsState()

            keycap(front).fill()
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "LayShift"
        return image
    }()
}

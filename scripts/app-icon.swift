import AppKit

// Draws the LayShift app icon: two keycaps, "A" in front and "Я" behind, on an indigo tile.
//   swift scripts/app-icon.swift <size> <out.png>
// scripts/make-icon.sh renders every size the asset catalog needs.

let args = CommandLine.arguments
let size = args.count > 1 ? CGFloat(Double(args[1]) ?? 1024) : 1024
let out = args.count > 2 ? args[2] : "icon.png"

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xff) / 255, green: CGFloat((hex >> 8) & 0xff) / 255, blue: CGFloat(hex & 0xff) / 255, alpha: alpha)
}

// Apple's icon grid: the shape fills ~82% of the canvas, corner radius ~22.5% of the shape
func squircle(in rect: NSRect) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.2237, yRadius: rect.height * 0.2237)
}

func keycapPath(_ rect: NSRect) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.18, yRadius: rect.height * 0.18)
}

func drawKeycap(_ rect: NSRect, depth: CGFloat, face: NSColor, side: NSColor, shadow: Bool = true) {
    if shadow {
        NSGraphicsContext.saveGraphicsState()
        let sh = NSShadow()
        sh.shadowColor = NSColor.black.withAlphaComponent(0.25)
        sh.shadowBlurRadius = rect.width * 0.06
        sh.shadowOffset = NSSize(width: 0, height: -rect.width * 0.04)
        sh.set()
        side.setFill()
        keycapPath(rect.offsetBy(dx: 0, dy: -depth)).fill()
        NSGraphicsContext.restoreGraphicsState()
    } else {
        side.setFill()
        keycapPath(rect.offsetBy(dx: 0, dy: -depth)).fill()
    }
    face.setFill()
    keycapPath(rect).fill()
    // subtle top highlight
    let highlight = NSGradient(starting: NSColor.white.withAlphaComponent(0.55), ending: NSColor.white.withAlphaComponent(0))!
    highlight.draw(in: keycapPath(rect), angle: -90)
}

func drawGlyph(_ text: String, in rect: NSRect, color: NSColor, scale: CGFloat = 0.62, weight: NSFont.Weight = .heavy) {
    let font = NSFont.systemFont(ofSize: rect.height * scale, weight: weight)
    let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.boundingRect(with: NSSize(width: 10_000, height: 10_000), options: [.usesLineFragmentOrigin])
    // center on the glyph's visual box rather than the line box
    let x = rect.midX - bounds.width / 2
    let y = rect.midY - bounds.height / 2 - font.descender * 0.25
    string.draw(at: NSPoint(x: x, y: y))
}

let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    let canvas = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.09
    let tile = canvas.insetBy(dx: inset, dy: inset)
    let shape = squircle(in: tile)

    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
    shadow.shadowBlurRadius = size * 0.02
    shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
    shadow.set()
    NSColor.black.setFill()
    shape.fill()
    NSGraphicsContext.restoreGraphicsState()

    NSGradient(starting: color(0x5A6CFF), ending: color(0x2B37B8))!.draw(in: shape, angle: -90)

    let face = color(0xF6F7FB)
    let side = color(0xB9C0E0)
    let ink = color(0x1C2350)
    let accent = color(0xFF8A3D)

    // the pair sits inside a comfortable margin so small sizes stay crisp
    let w = tile.width * 0.42
    let back = NSRect(x: tile.midX - w * 0.17, y: tile.midY - w * 0.12, width: w, height: w)
    let front = NSRect(x: tile.midX - w * 0.83, y: tile.midY - w * 0.78, width: w, height: w)
    drawKeycap(back, depth: tile.height * 0.035, face: face, side: side)
    drawGlyph("Я", in: back.insetBy(dx: w * 0.1, dy: w * 0.1), color: accent, scale: 0.7)
    drawKeycap(front, depth: tile.height * 0.035, face: face, side: side)
    drawGlyph("A", in: front.insetBy(dx: w * 0.1, dy: w * 0.1), color: ink, scale: 0.7)
    return true
}

let tiff = image.tiffRepresentation!
let rep = NSBitmapImageRep(data: tiff)!
let png = rep.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: out))

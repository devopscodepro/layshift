import AppKit

// Renders the LayShift app icon as PNG; scripts/make-icon.sh runs it for every size.
//   swiftc scripts/app-icon.swift LayShift/App/AppIconDrawing.swift -o app-icon && ./app-icon 1024 icon.png
@main
enum AppIconRenderer {
    static func main() throws {
        let args = CommandLine.arguments
        let size = args.count > 1 ? CGFloat(Double(args[1]) ?? 1024) : 1024
        let out = args.count > 2 ? args[2] : "icon.png"

        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            AppIconDrawing.draw(in: rect)
            return true
        }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            fatalError("could not render \(out)")
        }
        try png.write(to: URL(fileURLWithPath: out))
    }
}

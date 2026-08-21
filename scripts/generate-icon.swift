// One-off icon generator: draws a simple macOS-style rounded-square icon
// (gradient background + SF Symbol glyph) and writes icon-1024.png.
// Run with: swift scripts/generate-icon.swift
import AppKit

let size: CGFloat = 1024
let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

let corner: CGFloat = size * 0.225
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
path.addClip()

let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.29, green: 0.36, blue: 0.94, alpha: 1.0), // indigo
    NSColor(calibratedRed: 0.55, green: 0.27, blue: 0.86, alpha: 1.0), // violet
])
gradient?.draw(in: rect, angle: -60)

if let symbol = NSImage(systemSymbolName: "display", accessibilityDescription: nil) {
    let config = NSImage.SymbolConfiguration(pointSize: size * 0.42, weight: .medium)
    let glyph = symbol.withSymbolConfiguration(config) ?? symbol
    let glyphSize = glyph.size
    let origin = NSPoint(x: (size - glyphSize.width) / 2, y: (size - glyphSize.height) / 2 + size * 0.02)

    // Draw the SF Symbol tinted white via a template + fill.
    let tinted = NSImage(size: glyphSize)
    tinted.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: glyphSize).fill()
    glyph.draw(at: .zero, from: .zero, operation: .destinationIn, fraction: 1.0)
    tinted.unlockFocus()

    tinted.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 0.95)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not render icon")
}

let outURL = URL(fileURLWithPath: "icon-1024.png")
try! png.write(to: outURL)
print("wrote \(outURL.path)")

import AppKit
import Foundation

let outPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"
let side: CGFloat = 1024

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha)
}

let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                           pixelsWide: Int(side), pixelsHigh: Int(side),
                           bitsPerSample: 8, samplesPerPixel: 4,
                           hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB,
                           bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

let full = NSRect(x: 0, y: 0, width: side, height: side)
let bodyRect = full.insetBy(dx: 52, dy: 52)
let squircle = NSBezierPath(roundedRect: bodyRect, xRadius: 210, yRadius: 210)

// Base
squircle.addClip()
NSGradient(colors: [color(0x2A2233), color(0x131019)])!.draw(in: bodyRect, angle: -75)

// Warm glow
let glow = NSGradient(colors: [color(0xE3B84A, 0.30), color(0xE3B84A, 0.0)])!
glow.draw(fromCenter: NSPoint(x: side * 0.5, y: side * 0.84), radius: 0,
          toCenter: NSPoint(x: side * 0.5, y: side * 0.63), radius: side * 0.52,
          options: [])

// Grounding shadow
let shade = NSGradient(colors: [color(0x000000, 0.0), color(0x000000, 0.35)])!
shade.draw(in: NSRect(x: bodyRect.minX, y: bodyRect.minY, width: bodyRect.width, height: side * 0.42), angle: -90)

// Open book, drawn by hand so it stays crisp at every icon size.
let leftPage = NSBezierPath()
leftPage.move(to: NSPoint(x: 512, y: 706))
leftPage.curve(to: NSPoint(x: 268, y: 748),
               controlPoint1: NSPoint(x: 438, y: 748),
               controlPoint2: NSPoint(x: 338, y: 762))
leftPage.curve(to: NSPoint(x: 250, y: 340),
               controlPoint1: NSPoint(x: 246, y: 690),
               controlPoint2: NSPoint(x: 246, y: 430))
leftPage.curve(to: NSPoint(x: 512, y: 392),
               controlPoint1: NSPoint(x: 336, y: 300),
               controlPoint2: NSPoint(x: 430, y: 330))
leftPage.close()

let rightPage = NSBezierPath()
rightPage.move(to: NSPoint(x: 512, y: 706))
rightPage.curve(to: NSPoint(x: 756, y: 748),
                controlPoint1: NSPoint(x: 586, y: 748),
                controlPoint2: NSPoint(x: 686, y: 762))
rightPage.curve(to: NSPoint(x: 774, y: 340),
                controlPoint1: NSPoint(x: 778, y: 690),
                controlPoint2: NSPoint(x: 778, y: 430))
rightPage.curve(to: NSPoint(x: 512, y: 392),
                controlPoint1: NSPoint(x: 688, y: 300),
                controlPoint2: NSPoint(x: 594, y: 330))
rightPage.close()

let pageGradient = NSGradient(colors: [color(0xF2D382), color(0xC59A34), color(0xA97C22)],
                              atLocations: [0.0, 0.62, 1.0], colorSpace: .deviceRGB)!

NSGraphicsContext.saveGraphicsState()
let pageShadow = NSShadow()
pageShadow.shadowColor = color(0x000000, 0.55)
pageShadow.shadowBlurRadius = 42
pageShadow.shadowOffset = NSSize(width: 0, height: -22)
pageShadow.set()

for page in [leftPage, rightPage] {
    NSGraphicsContext.saveGraphicsState()
    page.addClip()
    pageGradient.draw(in: page.bounds, angle: -82)
    NSGraphicsContext.restoreGraphicsState()
}
NSGraphicsContext.restoreGraphicsState()

// Inner edge highlights
color(0xFFF4CC, 0.55).setStroke()
for page in [leftPage, rightPage] {
    page.lineWidth = 2.5
    page.stroke()
}

// Spine
let spine = NSBezierPath()
spine.move(to: NSPoint(x: 512, y: 388))
spine.line(to: NSPoint(x: 512, y: 708))
spine.lineWidth = 9
color(0x8A6418, 0.75).setStroke()
spine.stroke()

// Ribbon marker
let ribbon = NSBezierPath()
ribbon.move(to: NSPoint(x: 596, y: 512))
ribbon.line(to: NSPoint(x: 596, y: 700))
ribbon.curve(to: NSPoint(x: 648, y: 706),
             controlPoint1: NSPoint(x: 616, y: 706),
             controlPoint2: NSPoint(x: 630, y: 708))
ribbon.line(to: NSPoint(x: 648, y: 500))
ribbon.line(to: NSPoint(x: 622, y: 528))
ribbon.line(to: NSPoint(x: 596, y: 512))
ribbon.close()

NSGraphicsContext.saveGraphicsState()
let ribbonGradient = NSGradient(colors: [color(0x9E3B34), color(0x74241F)])!
ribbon.addClip()
ribbonGradient.draw(in: ribbon.bounds, angle: -90)
NSGraphicsContext.restoreGraphicsState()

// Inset hairline
NSGraphicsContext.restoreGraphicsState()

let border = NSBezierPath(roundedRect: bodyRect.insetBy(dx: 1.5, dy: 1.5), xRadius: 209, yRadius: 209)
border.lineWidth = 3
color(0xFFFFFF, 0.10).setStroke()
border.stroke()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}
try png.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")

import Foundation
import AppKit
import CoreGraphics

guard CommandLine.arguments.count >= 2 else {
    fputs("Usage: swift generate_icon.swift <output-iconset-dir> | --png <output-png-path>\n", stderr)
    exit(1)
}

let isSinglePNGMode = (CommandLine.arguments[1] == "--png")
if isSinglePNGMode && CommandLine.arguments.count < 3 {
    fputs("Usage: swift generate_icon.swift --png <output-png-path>\n", stderr)
    exit(1)
}

func renderIcon(pixelSize: Int) -> CGImage {
    let s = CGFloat(pixelSize)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        fatalError("Unable to create icon CGContext")
    }

    ctx.scaleBy(x: s / 1024.0, y: s / 1024.0)

    // macOS icon squircle safe area
    let inset: CGFloat = 100
    let box = CGRect(x: inset, y: inset, width: 1024 - inset * 2, height: 1024 - inset * 2)
    let cornerRadius: CGFloat = 185
    let squircle = CGPath(roundedRect: box, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Outer drop shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -18), blur: 32, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.addPath(squircle)
    ctx.setFillColor(CGColor(red: 0.14, green: 0.10, blue: 0.08, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Clip to squircle for backdrop
    ctx.saveGState()
    ctx.addPath(squircle)
    ctx.clip()

    let bgColors = [
        CGColor(red: 0.11, green: 0.085, blue: 0.07, alpha: 1.0),
        CGColor(red: 0.22, green: 0.16, blue: 0.115, alpha: 1.0),
        CGColor(red: 0.30, green: 0.22, blue: 0.15, alpha: 1.0)
    ] as CFArray
    if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 0.55, 1.0]) {
        ctx.drawLinearGradient(grad, start: CGPoint(x: 512, y: box.minY), end: CGPoint(x: 512, y: box.maxY), options: [])
    }

    // Subtle warm spotlight
    let glowColors = [
        CGColor(red: 0.96, green: 0.78, blue: 0.52, alpha: 0.22),
        CGColor(red: 0.96, green: 0.78, blue: 0.52, alpha: 0.0)
    ] as CFArray
    if let glow = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(
            glow,
            startCenter: CGPoint(x: 512, y: 680),
            startRadius: 10,
            endCenter: CGPoint(x: 512, y: 620),
            endRadius: 420,
            options: []
        )
    }

    // Curved braided clothesline (y=720 at edges sagging to y=615 in middle; bottom-up coords!)
    let ropeStart = CGPoint(x: box.minX - 20, y: 745)
    let ropeEnd = CGPoint(x: box.maxX + 20, y: 745)
    let ropeControl = CGPoint(x: 512, y: 545)

    // Rope shadow
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
    ctx.setLineWidth(24)
    ctx.setLineCap(.round)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: ropeStart.x, y: ropeStart.y - 12))
    ctx.addQuadCurve(to: CGPoint(x: ropeEnd.x, y: ropeEnd.y - 12), control: CGPoint(x: ropeControl.x, y: ropeControl.y - 12))
    ctx.strokePath()
    ctx.restoreGState()

    // Rope body
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.76, green: 0.58, blue: 0.36, alpha: 1.0))
    ctx.setLineWidth(20)
    ctx.setLineCap(.round)
    ctx.beginPath()
    ctx.move(to: ropeStart)
    ctx.addQuadCurve(to: ropeEnd, control: ropeControl)
    ctx.strokePath()

    ctx.setStrokeColor(CGColor(red: 0.92, green: 0.79, blue: 0.58, alpha: 0.85))
    ctx.setLineWidth(8)
    ctx.beginPath()
    ctx.move(to: CGPoint(x: ropeStart.x, y: ropeStart.y + 3))
    ctx.addQuadCurve(to: CGPoint(x: ropeEnd.x, y: ropeEnd.y + 3), control: CGPoint(x: ropeControl.x, y: ropeControl.y + 3))
    ctx.strokePath()
    ctx.restoreGState()

    func ropeYAt(t: CGFloat) -> CGFloat {
        let u = 1.0 - t
        return u * u * ropeStart.y + 2 * u * t * ropeControl.y + t * t * ropeEnd.y
    }

    func drawMiniPolaroid(
        centerX: CGFloat,
        ropeY: CGFloat,
        width: CGFloat,
        height: CGFloat,
        angle: CGFloat,
        topColor: CGColor,
        bottomColor: CGColor
    ) {
        ctx.saveGState()
        ctx.translateBy(x: centerX, y: ropeY)
        ctx.rotate(by: angle)

        let cardRect = CGRect(x: -width * 0.5, y: -height + 8, width: width, height: height)
        let cardPath = CGPath(roundedRect: cardRect, cornerWidth: 10, cornerHeight: 10, transform: nil)

        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 24, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.45))
        ctx.addPath(cardPath)
        ctx.setFillColor(CGColor(red: 0.985, green: 0.975, blue: 0.955, alpha: 1.0))
        ctx.fillPath()
        ctx.restoreGState()

        // Inner photo gradient
        let inset: CGFloat = width * 0.085
        let photoRect = CGRect(
            x: cardRect.minX + inset,
            y: cardRect.minY + height * 0.19,
            width: width - inset * 2,
            height: height * 0.71
        )
        ctx.saveGState()
        ctx.clip(to: photoRect)
        let colors = [bottomColor, topColor] as CFArray
        if let g = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(g, start: CGPoint(x: photoRect.midX, y: photoRect.minY), end: CGPoint(x: photoRect.midX, y: photoRect.maxY), options: [])
        }
        ctx.restoreGState()

        // Wooden clothespin
        let pinRect = CGRect(x: -17, y: -22, width: 34, height: 82)
        let pinPath = CGPath(roundedRect: pinRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        ctx.saveGState()
        ctx.setShadow(offset: CGSize(width: 3, height: -5), blur: 8, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.35))
        ctx.addPath(pinPath)
        ctx.setFillColor(CGColor(red: 0.84, green: 0.65, blue: 0.41, alpha: 1.0))
        ctx.fillPath()
        ctx.restoreGState()

        // Clothespin spring band
        ctx.setFillColor(CGColor(red: 0.76, green: 0.80, blue: 0.86, alpha: 1.0))
        ctx.fill(CGRect(x: -19, y: 12, width: 38, height: 8))

        ctx.restoreGState()
    }

    drawMiniPolaroid(
        centerX: 295,
        ropeY: ropeYAt(t: 0.23),
        width: 205,
        height: 238,
        angle: 0.11,
        topColor: CGColor(red: 0.25, green: 0.52, blue: 0.86, alpha: 1.0),
        bottomColor: CGColor(red: 0.14, green: 0.28, blue: 0.54, alpha: 1.0)
    )
    drawMiniPolaroid(
        centerX: 730,
        ropeY: ropeYAt(t: 0.77),
        width: 205,
        height: 238,
        angle: -0.09,
        topColor: CGColor(red: 0.22, green: 0.70, blue: 0.65, alpha: 1.0),
        bottomColor: CGColor(red: 0.11, green: 0.38, blue: 0.48, alpha: 1.0)
    )
    drawMiniPolaroid(
        centerX: 512,
        ropeY: ropeYAt(t: 0.50),
        width: 245,
        height: 282,
        angle: -0.04,
        topColor: CGColor(red: 0.96, green: 0.58, blue: 0.32, alpha: 1.0),
        bottomColor: CGColor(red: 0.72, green: 0.25, blue: 0.45, alpha: 1.0)
    )

    ctx.restoreGState()

    // Inner specular border on squircle
    ctx.addPath(squircle)
    ctx.setStrokeColor(CGColor(red: 1.0, green: 0.93, blue: 0.84, alpha: 0.18))
    ctx.setLineWidth(4)
    ctx.strokePath()

    return ctx.makeImage()!
}

let entries: [(name: String, px: Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

if isSinglePNGMode {
    let outURL = URL(fileURLWithPath: CommandLine.arguments[2])
    try FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    let image = renderIcon(pixelSize: 512)
    let rep = NSBitmapImageRep(cgImage: image)
    guard let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to encode PNG")
    }
    try png.write(to: outURL)
    print("Generated icon PNG at \(outURL.path)")
} else {
    let iconsetURL = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)
    for entry in entries {
        let image = renderIcon(pixelSize: entry.px)
        let rep = NSBitmapImageRep(cgImage: image)
        guard let png = rep.representation(using: .png, properties: [:]) else {
            fatalError("Failed to encode PNG for \(entry.name)")
        }
        try png.write(to: iconsetURL.appendingPathComponent(entry.name))
    }
    print("Generated iconset at \(iconsetURL.path)")
}

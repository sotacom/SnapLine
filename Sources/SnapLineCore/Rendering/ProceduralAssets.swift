import Foundation
import AppKit
import CoreGraphics

public enum ProceduralAssets {
    public static let scale: CGFloat = 2.0

    public static let braidedRopeTile: CGImage = renderBraidedRopeTile()
    public static let clothespinImage: CGImage = renderClothespinImage()

    public static let copyIcon: CGImage? = renderSymbol("doc.on.doc", pointSize: 13, weight: .medium, color: .white)
    public static let checkmarkIcon: CGImage? = renderSymbol("checkmark", pointSize: 13, weight: .bold, color: NSColor(calibratedRed: 0.42, green: 0.92, blue: 0.56, alpha: 1.0))
    public static let finderIcon: CGImage? = renderSymbol("folder", pointSize: 13, weight: .medium, color: .white)
    public static let trashIcon: CGImage? = renderSymbol("trash", pointSize: 13, weight: .medium, color: NSColor(calibratedRed: 1.0, green: 0.45, blue: 0.42, alpha: 1.0))
    public static let playIcon: CGImage? = renderSymbol("play.fill", pointSize: 9.5, weight: .bold, color: .white)

    public static func makeMenuBarIcon() -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.setStrokeColor(NSColor.black.cgColor)
            ctx.setFillColor(NSColor.black.cgColor)

            // Curved clothesline rope across top
            let rope = CGMutablePath()
            rope.move(to: CGPoint(x: 1.2, y: 14.2))
            rope.addQuadCurve(to: CGPoint(x: 18.8, y: 14.2), control: CGPoint(x: 10.0, y: 11.2))
            ctx.setLineWidth(1.5)
            ctx.setLineCap(.round)
            ctx.addPath(rope)
            ctx.strokePath()

            // Left mini polaroid tilted slightly
            ctx.saveGState()
            ctx.translateBy(x: 6.2, y: 12.6)
            ctx.rotate(by: 0.12)
            let leftCard = CGRect(x: -3.2, y: -8.6, width: 6.4, height: 7.8)
            ctx.setLineWidth(1.25)
            ctx.stroke(leftCard)
            ctx.fill(CGRect(x: -0.7, y: -1.1, width: 1.4, height: 2.3))
            ctx.restoreGState()

            // Right mini polaroid tilted slightly opposite
            ctx.saveGState()
            ctx.translateBy(x: 13.8, y: 12.6)
            ctx.rotate(by: -0.09)
            let rightCard = CGRect(x: -3.4, y: -8.8, width: 6.8, height: 8.0)
            ctx.setLineWidth(1.25)
            ctx.stroke(rightCard)
            ctx.fill(CGRect(x: -0.7, y: -1.1, width: 1.4, height: 2.3))
            ctx.restoreGState()

            return true
        }
        image.isTemplate = true
        return image
    }

    private static func renderBraidedRopeTile() -> CGImage {
        let logicalWidth: CGFloat = 64
        let logicalHeight: CGFloat = 11
        let pxW = Int(logicalWidth * scale)
        let pxH = Int(logicalHeight * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pxW,
            height: pxH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Failed to create CGContext for braidedRopeTile")
        }

        ctx.scaleBy(x: scale, y: scale)

        // Clip to horizontal rope body with slight organic edge
        let ropeRect = CGRect(x: 0, y: 1.5, width: logicalWidth, height: logicalHeight - 3.0)
        ctx.saveGState()
        ctx.clip(to: ropeRect)

        // Base warm jute fill
        let baseColors = [
            CGColor(red: 0.50, green: 0.35, blue: 0.19, alpha: 1.0),
            CGColor(red: 0.78, green: 0.60, blue: 0.37, alpha: 1.0),
            CGColor(red: 0.87, green: 0.73, blue: 0.51, alpha: 1.0),
            CGColor(red: 0.66, green: 0.47, blue: 0.27, alpha: 1.0),
            CGColor(red: 0.42, green: 0.28, blue: 0.14, alpha: 1.0)
        ] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: baseColors, locations: [0.0, 0.25, 0.55, 0.8, 1.0]) {
            ctx.drawLinearGradient(
                grad,
                start: CGPoint(x: 0, y: ropeRect.minY),
                end: CGPoint(x: 0, y: ropeRect.maxY),
                options: []
            )
        }

        // Seamless repeating braided twist strands (period = 16pt across 64pt tile)
        let period: CGFloat = 16.0
        for idx in -2...5 {
            let x0 = CGFloat(idx) * period
            // Dark twist crevice
            ctx.setStrokeColor(CGColor(red: 0.32, green: 0.21, blue: 0.10, alpha: 0.68))
            ctx.setLineWidth(2.4)
            ctx.setLineCap(.round)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x0, y: ropeRect.minY - 1))
            ctx.addCurve(
                to: CGPoint(x: x0 + period * 0.72, y: ropeRect.maxY + 1),
                control1: CGPoint(x: x0 + period * 0.25, y: ropeRect.midY - 1.2),
                control2: CGPoint(x: x0 + period * 0.50, y: ropeRect.midY + 1.2)
            )
            ctx.strokePath()

            // Highlighted golden hemp twist strand
            ctx.setStrokeColor(CGColor(red: 0.94, green: 0.83, blue: 0.64, alpha: 0.78))
            ctx.setLineWidth(2.0)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x0 + 3.2, y: ropeRect.minY))
            ctx.addCurve(
                to: CGPoint(x: x0 + 3.2 + period * 0.68, y: ropeRect.maxY),
                control1: CGPoint(x: x0 + 3.2 + period * 0.22, y: ropeRect.midY - 0.8),
                control2: CGPoint(x: x0 + 3.2 + period * 0.48, y: ropeRect.midY + 1.0)
            )
            ctx.strokePath()

            // Counter strand shadow
            ctx.setStrokeColor(CGColor(red: 0.45, green: 0.30, blue: 0.15, alpha: 0.42))
            ctx.setLineWidth(1.2)
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x0 + 7.5, y: ropeRect.minY + 0.5))
            ctx.addLine(to: CGPoint(x: x0 + 13.5, y: ropeRect.maxY - 0.5))
            ctx.strokePath()
        }

        // Fine fibrous hemp hairlines
        ctx.setStrokeColor(CGColor(red: 0.98, green: 0.90, blue: 0.76, alpha: 0.32))
        ctx.setLineWidth(0.6)
        for i in 0..<12 {
            let x = CGFloat(i) * 5.4
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: ropeRect.midY + (i % 2 == 0 ? 1.2 : -1.0)))
            ctx.addLine(to: CGPoint(x: x + 4.8, y: ropeRect.midY + (i % 2 == 0 ? 2.1 : 0.2)))
            ctx.strokePath()
        }

        // Subtle rim shading
        ctx.setStrokeColor(CGColor(red: 0.24, green: 0.15, blue: 0.07, alpha: 0.55))
        ctx.setLineWidth(0.9)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 0, y: ropeRect.minY + 0.4))
        ctx.addLine(to: CGPoint(x: logicalWidth, y: ropeRect.minY + 0.4))
        ctx.strokePath()

        ctx.restoreGState()

        // Delicate stray hemp fuzz along outer edges
        ctx.setStrokeColor(CGColor(red: 0.82, green: 0.67, blue: 0.45, alpha: 0.42))
        ctx.setLineWidth(0.55)
        for i in 0..<8 {
            let x = CGFloat(i) * 8.1 + 1.5
            ctx.beginPath()
            ctx.move(to: CGPoint(x: x, y: ropeRect.maxY - 0.3))
            ctx.addQuadCurve(
                to: CGPoint(x: x + 3.4, y: ropeRect.maxY + 1.1),
                control: CGPoint(x: x + 1.6, y: ropeRect.maxY + 0.8)
            )
            ctx.strokePath()
        }

        return ctx.makeImage()!
    }

    private static func renderClothespinImage() -> CGImage {
        // Logical size: 28 x 62 pt. Bottom (y=0) is jaw clamping Polaroid; Top (y=62) is handle tips.
        let logicalWidth: CGFloat = 28
        let logicalHeight: CGFloat = 62
        let pxW = Int(logicalWidth * scale)
        let pxH = Int(logicalHeight * scale)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pxW,
            height: pxH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            fatalError("Failed to create CGContext for clothespinImage")
        }

        ctx.scaleBy(x: scale, y: scale)

        // Pin silhouette path (with gentle ergonomic finger waist in middle)
        let bodyPath = CGMutablePath()
        let leftX: CGFloat = 7.2
        let rightX: CGFloat = 20.8
        let bottomY: CGFloat = 4.0
        let topY: CGFloat = 59.0

        bodyPath.move(to: CGPoint(x: leftX + 1.2, y: bottomY))
        bodyPath.addLine(to: CGPoint(x: rightX - 1.2, y: bottomY))
        bodyPath.addQuadCurve(to: CGPoint(x: rightX, y: bottomY + 1.6), control: CGPoint(x: rightX, y: bottomY))
        // Right side up through waist notch
        bodyPath.addLine(to: CGPoint(x: rightX - 0.3, y: 24.0))
        bodyPath.addQuadCurve(to: CGPoint(x: rightX - 1.5, y: 31.0), control: CGPoint(x: rightX - 1.8, y: 27.5))
        bodyPath.addLine(to: CGPoint(x: rightX - 0.1, y: 37.5))
        bodyPath.addLine(to: CGPoint(x: rightX + 0.4, y: topY - 2.0))
        bodyPath.addQuadCurve(to: CGPoint(x: rightX - 1.5, y: topY), control: CGPoint(x: rightX + 0.4, y: topY))
        // Top slightly split into two prongs
        bodyPath.addLine(to: CGPoint(x: 15.1, y: topY))
        bodyPath.addLine(to: CGPoint(x: 14.7, y: 33.0))
        bodyPath.addLine(to: CGPoint(x: 13.3, y: 33.0))
        bodyPath.addLine(to: CGPoint(x: 12.9, y: topY))
        bodyPath.addLine(to: CGPoint(x: leftX + 1.5, y: topY))
        bodyPath.addQuadCurve(to: CGPoint(x: leftX - 0.4, y: topY - 2.0), control: CGPoint(x: leftX - 0.4, y: topY))
        // Left side down through waist notch
        bodyPath.addLine(to: CGPoint(x: leftX + 0.1, y: 37.5))
        bodyPath.addLine(to: CGPoint(x: leftX + 1.5, y: 31.0))
        bodyPath.addQuadCurve(to: CGPoint(x: leftX + 0.3, y: 24.0), control: CGPoint(x: leftX + 1.8, y: 27.5))
        bodyPath.addLine(to: CGPoint(x: leftX, y: bottomY + 1.6))
        bodyPath.addQuadCurve(to: CGPoint(x: leftX + 1.2, y: bottomY), control: CGPoint(x: leftX, y: bottomY))
        bodyPath.closeSubpath()

        // Cast drop shadow onto Polaroid & rope
        ctx.saveGState()
        ctx.setShadow(
            offset: CGSize(width: 1.2, height: -2.2),
            blur: 3.2,
            color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.34)
        )
        ctx.addPath(bodyPath)
        ctx.setFillColor(CGColor(red: 0.80, green: 0.62, blue: 0.40, alpha: 1.0))
        ctx.fillPath()
        ctx.restoreGState()

        // Clip inside body for wood gradient and grain
        ctx.saveGState()
        ctx.addPath(bodyPath)
        ctx.clip()

        let woodColors = [
            CGColor(red: 0.72, green: 0.51, blue: 0.29, alpha: 1.0),
            CGColor(red: 0.89, green: 0.73, blue: 0.51, alpha: 1.0),
            CGColor(red: 0.85, green: 0.67, blue: 0.45, alpha: 1.0),
            CGColor(red: 0.66, green: 0.46, blue: 0.26, alpha: 1.0)
        ] as CFArray
        if let woodGrad = CGGradient(colorsSpace: colorSpace, colors: woodColors, locations: [0.0, 0.32, 0.68, 1.0]) {
            ctx.drawLinearGradient(
                woodGrad,
                start: CGPoint(x: leftX, y: 30),
                end: CGPoint(x: rightX, y: 30),
                options: []
            )
        }

        // Vertical wood grain streaks
        ctx.setLineWidth(0.55)
        let grainPositions: [CGFloat] = [8.6, 10.3, 12.1, 15.8, 17.5, 19.3]
        for (idx, gx) in grainPositions.enumerated() {
            ctx.setStrokeColor(CGColor(red: 0.54, green: 0.36, blue: 0.18, alpha: idx % 2 == 0 ? 0.22 : 0.14))
            ctx.beginPath()
            ctx.move(to: CGPoint(x: gx, y: bottomY))
            ctx.addCurve(
                to: CGPoint(x: gx + (idx % 2 == 0 ? 0.5 : -0.4), y: topY),
                control1: CGPoint(x: gx + 0.7, y: 20),
                control2: CGPoint(x: gx - 0.6, y: 42)
            )
            ctx.strokePath()
        }

        // Front-to-back lighting bevel at bottom jaw tip
        let jawBevelColors = [
            CGColor(red: 0.36, green: 0.22, blue: 0.10, alpha: 0.34),
            CGColor(red: 0.96, green: 0.87, blue: 0.72, alpha: 0.12),
            CGColor(red: 0, green: 0, blue: 0, alpha: 0)
        ] as CFArray
        if let jawGrad = CGGradient(colorsSpace: colorSpace, colors: jawBevelColors, locations: [0.0, 0.22, 0.65]) {
            ctx.drawLinearGradient(
                jawGrad,
                start: CGPoint(x: 14, y: bottomY),
                end: CGPoint(x: 14, y: 22),
                options: []
            )
        }

        // Center split shadow line down lower jaw
        ctx.setStrokeColor(CGColor(red: 0.38, green: 0.24, blue: 0.12, alpha: 0.48))
        ctx.setLineWidth(0.8)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 14.0, y: bottomY + 1.0))
        ctx.addLine(to: CGPoint(x: 14.0, y: 24.0))
        ctx.strokePath()

        ctx.restoreGState()

        // Crisp subtle wood edge stroke
        ctx.addPath(bodyPath)
        ctx.setStrokeColor(CGColor(red: 0.44, green: 0.28, blue: 0.14, alpha: 0.55))
        ctx.setLineWidth(0.7)
        ctx.strokePath()

        // Metallic coiled spring wrap across the waist (y ~ 26..30)
        ctx.saveGState()
        let springRect = CGRect(x: 6.4, y: 25.8, width: 15.2, height: 4.0)
        let springPath = CGPath(roundedRect: springRect, cornerWidth: 1.6, cornerHeight: 1.6, transform: nil)
        ctx.addPath(springPath)
        ctx.setFillColor(CGColor(red: 0.68, green: 0.71, blue: 0.76, alpha: 1.0))
        ctx.fillPath()

        // Metallic highlight band across spring
        ctx.setStrokeColor(CGColor(red: 0.95, green: 0.97, blue: 1.0, alpha: 0.9))
        ctx.setLineWidth(1.1)
        ctx.beginPath()
        ctx.move(to: CGPoint(x: 7.4, y: 28.2))
        ctx.addLine(to: CGPoint(x: 20.6, y: 28.2))
        ctx.strokePath()

        // Dark coil rings
        ctx.setStrokeColor(CGColor(red: 0.30, green: 0.33, blue: 0.38, alpha: 0.85))
        ctx.setLineWidth(0.8)
        for coilX in stride(from: 8.2, through: 19.8, by: 2.3) {
            ctx.beginPath()
            ctx.move(to: CGPoint(x: coilX, y: 25.9))
            ctx.addLine(to: CGPoint(x: coilX + 0.6, y: 29.7))
            ctx.strokePath()
        }
        ctx.restoreGState()

        return ctx.makeImage()!
    }

    private static func renderSymbol(
        _ symbolName: String,
        pointSize: CGFloat,
        weight: NSFont.Weight,
        color: NSColor
    ) -> CGImage? {
        let config = NSImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        guard let base = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else {
            return nil
        }

        let targetSize = NSSize(width: ceil(base.size.width + 4), height: ceil(base.size.height + 4))
        let tinted = NSImage(size: targetSize, flipped: false) { rect in
            color.set()
            let drawRect = NSRect(
                x: (rect.width - base.size.width) * 0.5,
                y: (rect.height - base.size.height) * 0.5,
                width: base.size.width,
                height: base.size.height
            )
            base.draw(in: drawRect)
            drawRect.fill(using: .sourceAtop)
            return true
        }
        var proposedRect = NSRect(origin: .zero, size: targetSize)
        return tinted.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }
}

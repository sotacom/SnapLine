import Foundation
import AppKit
import ImageIO
import UniformTypeIdentifiers
import SnapLineCore

@MainActor
func renderSnapshotForItems(_ items: [MediaItem], to outputPath: String, hoverIndexFromRight: Int = 2) -> Int32 {
    var remaining = items.count
    for item in items {
        ThumbnailPipeline.shared.requestThumbnail(for: item) { _ in
            remaining -= 1
        }
    }

    let deadline = Date().addingTimeInterval(5.0)
    while remaining > 0 && Date() < deadline {
        RunLoop.main.run(mode: .default, before: Date().addingTimeInterval(0.02))
    }

    let viewSize = CGSize(width: 1440, height: 340)
    let view = ClotheslineView(frame: NSRect(origin: .zero, size: viewSize))
    view.setItems(items, resetScroll: true)

    if items.count >= hoverIndexFromRight {
        let hovered = items[items.count - hoverIndexFromRight]
        let tuples = items.map { ($0.id, $0.restingAngle) }
        view.physics.setHovered(itemID: hovered.id, visibleItems: tuples)
        for _ in 0..<30 {
            _ = view.physics.step(dt: 1.0 / 60.0, orderedItemIDs: items.map(\.id))
        }
    }

    let bg = CGColor(red: 0.94, green: 0.91, blue: 0.86, alpha: 1.0)
    guard let image = view.renderSnapshot(size: viewSize, scale: 2.0, backgroundColor: bg) else {
        fputs("Failed to render snapshot\n", stderr)
        return 1
    }

    let outURL = URL(fileURLWithPath: outputPath)
    try? FileManager.default.createDirectory(at: outURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    guard let dest = CGImageDestinationCreateWithURL(outURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        fputs("Failed to create PNG destination at \(outputPath)\n", stderr)
        return 1
    }
    CGImageDestinationAddImage(dest, image, nil)
    guard CGImageDestinationFinalize(dest) else {
        fputs("Failed to write PNG at \(outputPath)\n", stderr)
        return 1
    }

    print("Rendered snapshot (\(image.width)x\(image.height)) -> \(outputPath)")
    return 0
}

@MainActor
func renderPreviewPNG(to outputPath: String) -> Int32 {
    _ = NSApplication.shared
    let folderURL = SystemScreenshotConfig.readSystemLocation()
    let items = Array(ScreenshotStore.scanDirectory(url: folderURL).suffix(7))
    if items.isEmpty {
        fputs("No screenshots found in \(folderURL.path)\n", stderr)
        return 1
    }
    return renderSnapshotForItems(items, to: outputPath)
}

func makeSyntheticCardCGImage(kind: Int, width: Int = 720, height: Int = 520) -> CGImage {
    let cs = CGColorSpaceCreateDeviceRGB()
    let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!

    let w = CGFloat(width)
    let h = CGFloat(height)

    func drawTrafficLights(x: CGFloat, y: CGFloat) {
        let colors = [
            CGColor(red: 0.98, green: 0.37, blue: 0.34, alpha: 1),
            CGColor(red: 0.98, green: 0.74, blue: 0.21, alpha: 1),
            CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1)
        ]
        for (i, c) in colors.enumerated() {
            ctx.setFillColor(c)
            ctx.fillEllipse(in: CGRect(x: x + CGFloat(i) * 24, y: y, width: 14, height: 14))
        }
    }

    switch kind {
    case 0:
        // Dark Swift Code Editor
        ctx.setFillColor(CGColor(red: 0.11, green: 0.12, blue: 0.15, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setFillColor(CGColor(red: 0.15, green: 0.16, blue: 0.20, alpha: 1))
        ctx.fill(CGRect(x: 0, y: h - 46, width: w, height: 46))
        drawTrafficLights(x: 20, y: h - 30)
        let lineColors = [
            CGColor(red: 0.96, green: 0.51, blue: 0.67, alpha: 0.95),
            CGColor(red: 0.48, green: 0.80, blue: 0.98, alpha: 0.95),
            CGColor(red: 0.65, green: 0.89, blue: 0.56, alpha: 0.95),
            CGColor(red: 0.96, green: 0.79, blue: 0.45, alpha: 0.95),
            CGColor(red: 0.78, green: 0.82, blue: 0.89, alpha: 0.75)
        ]
        for row in 0..<11 {
            let y = h - 92 - CGFloat(row) * 34
            let indent = CGFloat((row % 3) * 28 + 34)
            let len1 = CGFloat(90 + (row * 37) % 140)
            ctx.setFillColor(lineColors[row % lineColors.count])
            ctx.addPath(CGPath(roundedRect: CGRect(x: indent, y: y, width: len1, height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil))
            ctx.fillPath()
            ctx.setFillColor(lineColors[(row + 2) % lineColors.count])
            ctx.addPath(CGPath(roundedRect: CGRect(x: indent + len1 + 14, y: y, width: CGFloat(80 + (row * 53) % 180), height: 12), cornerWidth: 6, cornerHeight: 6, transform: nil))
            ctx.fillPath()
        }
    case 1:
        // Clean Analytics Dashboard
        ctx.setFillColor(CGColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.setFillColor(CGColor(red: 0.90, green: 0.93, blue: 0.98, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: 150, height: h))
        let barColors = [
            CGColor(red: 0.27, green: 0.50, blue: 0.95, alpha: 1),
            CGColor(red: 0.36, green: 0.67, blue: 0.98, alpha: 1),
            CGColor(red: 0.18, green: 0.78, blue: 0.62, alpha: 1),
            CGColor(red: 0.96, green: 0.63, blue: 0.25, alpha: 1)
        ]
        for i in 0..<7 {
            let bh = CGFloat(120 + ((i * 67) % 210))
            ctx.setFillColor(barColors[i % barColors.count])
            ctx.fill(CGRect(x: 195 + CGFloat(i) * 68, y: 70, width: 42, height: bh))
        }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 195, y: 340, width: 220, height: 120))
        ctx.fill(CGRect(x: 440, y: 340, width: 220, height: 120))
    case 2:
        // Warm Sunset Mountain Landscape
        let skyColors = [
            CGColor(red: 0.97, green: 0.64, blue: 0.42, alpha: 1),
            CGColor(red: 0.95, green: 0.43, blue: 0.46, alpha: 1),
            CGColor(red: 0.34, green: 0.27, blue: 0.49, alpha: 1)
        ] as CFArray
        let grad = CGGradient(colorsSpace: cs, colors: skyColors, locations: [0.0, 0.45, 1.0])!
        ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: h), options: [])
        ctx.setFillColor(CGColor(red: 1.0, green: 0.91, blue: 0.68, alpha: 0.92))
        ctx.fillEllipse(in: CGRect(x: 290, y: 230, width: 140, height: 140))
        let mtn1 = CGMutablePath()
        mtn1.move(to: CGPoint(x: 0, y: 0))
        mtn1.addLine(to: CGPoint(x: 0, y: 220))
        mtn1.addLine(to: CGPoint(x: 240, y: 310))
        mtn1.addLine(to: CGPoint(x: 490, y: 190))
        mtn1.addLine(to: CGPoint(x: w, y: 270))
        mtn1.addLine(to: CGPoint(x: w, y: 0))
        mtn1.closeSubpath()
        ctx.addPath(mtn1)
        ctx.setFillColor(CGColor(red: 0.23, green: 0.16, blue: 0.30, alpha: 0.92))
        ctx.fillPath()
        let mtn2 = CGMutablePath()
        mtn2.move(to: CGPoint(x: 0, y: 0))
        mtn2.addLine(to: CGPoint(x: 0, y: 145))
        mtn2.addLine(to: CGPoint(x: 340, y: 215))
        mtn2.addLine(to: CGPoint(x: w, y: 120))
        mtn2.addLine(to: CGPoint(x: w, y: 0))
        mtn2.closeSubpath()
        ctx.addPath(mtn2)
        ctx.setFillColor(CGColor(red: 0.12, green: 0.08, blue: 0.18, alpha: 1))
        ctx.fillPath()
    case 3:
        // Design System Palette Board
        ctx.setFillColor(CGColor(red: 0.98, green: 0.96, blue: 0.93, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        let swatches = [
            CGColor(red: 0.85, green: 0.42, blue: 0.30, alpha: 1),
            CGColor(red: 0.89, green: 0.67, blue: 0.32, alpha: 1),
            CGColor(red: 0.26, green: 0.56, blue: 0.50, alpha: 1),
            CGColor(red: 0.22, green: 0.33, blue: 0.56, alpha: 1),
            CGColor(red: 0.48, green: 0.36, blue: 0.58, alpha: 1),
            CGColor(red: 0.18, green: 0.16, blue: 0.15, alpha: 1)
        ]
        for i in 0..<6 {
            let col = i % 3
            let row = i / 3
            let rx = 70 + CGFloat(col) * 205
            let ry = 285 - CGFloat(row) * 215
            ctx.setFillColor(swatches[i])
            ctx.fill(CGRect(x: rx, y: ry, width: 170, height: 170))
        }
    case 4:
        // Terminal Build Success Window
        ctx.setFillColor(CGColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        drawTrafficLights(x: 24, y: h - 36)
        ctx.setFillColor(CGColor(red: 0.25, green: 0.86, blue: 0.48, alpha: 0.95))
        for row in 0..<7 {
            let y = h - 105 - CGFloat(row) * 52
            ctx.fillEllipse(in: CGRect(x: 34, y: y, width: 16, height: 16))
            ctx.setFillColor(CGColor(red: 0.86, green: 0.90, blue: 0.94, alpha: 0.85))
            ctx.fill(CGRect(x: 68, y: y + 2, width: CGFloat(240 + (row * 71) % 280), height: 12))
            ctx.setFillColor(CGColor(red: 0.25, green: 0.86, blue: 0.48, alpha: 0.95))
        }
    case 5:
        // Product Web Mockup (hovered card with glass action pill!)
        let webColors = [
            CGColor(red: 0.13, green: 0.43, blue: 0.47, alpha: 1),
            CGColor(red: 0.08, green: 0.22, blue: 0.29, alpha: 1)
        ] as CFArray
        let wg = CGGradient(colorsSpace: cs, colors: webColors, locations: [0, 1])!
        ctx.drawLinearGradient(wg, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.14))
        ctx.fill(CGRect(x: 48, y: 240, width: 624, height: 190))
        ctx.setFillColor(CGColor(red: 0.98, green: 0.78, blue: 0.45, alpha: 0.95))
        ctx.fill(CGRect(x: 84, y: 315, width: 220, height: 42))
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.85))
        ctx.fill(CGRect(x: 84, y: 374, width: 340, height: 22))
    default:
        // Architectural / Photo Card
        let colors = [
            CGColor(red: 0.92, green: 0.84, blue: 0.72, alpha: 1),
            CGColor(red: 0.73, green: 0.56, blue: 0.39, alpha: 1)
        ] as CFArray
        let g = CGGradient(colorsSpace: cs, colors: colors, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: h), end: CGPoint(x: w, y: 0), options: [])
        ctx.setFillColor(CGColor(red: 0.18, green: 0.14, blue: 0.11, alpha: 0.85))
        ctx.fill(CGRect(x: 90, y: 90, width: 540, height: 340))
        ctx.setFillColor(CGColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1))
        ctx.fill(CGRect(x: 130, y: 140, width: 220, height: 240))
        ctx.setFillColor(CGColor(red: 0.89, green: 0.52, blue: 0.31, alpha: 1))
        ctx.fillEllipse(in: CGRect(x: 410, y: 170, width: 170, height: 170))
    }

    return ctx.makeImage()!
}

@MainActor
func renderShowcasePNG(to outputPath: String) -> Int32 {
    _ = NSApplication.shared

    let tempDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("SnapLineShowcase-\(UUID().uuidString)", isDirectory: true)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: tempDir) }

    let now = Date()
    let agesSeconds: [TimeInterval] = [
        -3 * 86400,
        -2 * 86400,
        -2 * 86400 + 3600,
        -1 * 86400,
        -1 * 86400 + 7200,
        -1800,
        -120
    ]

    var items: [MediaItem] = []
    for i in 0..<7 {
        let img = makeSyntheticCardCGImage(kind: i)
        let url = tempDir.appendingPathComponent("Showcase \(i + 1).png")
        if let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dest, img, nil)
            CGImageDestinationFinalize(dest)
        }
        let date = now.addingTimeInterval(agesSeconds[i])
        try? FileManager.default.setAttributes([.creationDate: date, .modificationDate: date], ofItemAtPath: url.path)
        let item = MediaItem(url: url, createdAt: date, modifiedAt: date, fileSize: 1024, mediaType: .image)
        items.append(item)
    }

    return renderSnapshotForItems(items, to: outputPath, hoverIndexFromRight: 2)
}

MainActor.assumeIsolated {
    let args = CommandLine.arguments
    if let idx = args.firstIndex(of: "--render-preview"), idx + 1 < args.count {
        exit(renderPreviewPNG(to: args[idx + 1]))
    }
    if let idx = args.firstIndex(of: "--render-showcase"), idx + 1 < args.count {
        exit(renderShowcasePNG(to: args[idx + 1]))
    }

    let runner = TestRunner()
    PhysicsEngineTests.register(into: runner)
    MediaStoreTests.register(into: runner)
    VirtualizationTests.register(into: runner)
    exit(runner.runAll())
}

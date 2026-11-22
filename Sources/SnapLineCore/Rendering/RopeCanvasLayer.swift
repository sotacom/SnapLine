import Foundation
import CoreGraphics
import QuartzCore

public final class RopeCanvasLayer: CALayer {
    public var ropeSampler: ((CGFloat) -> CGFloat)?
    public var curtainOpacity: CGFloat = 1.0

    private let ropeTile = ProceduralAssets.braidedRopeTile
    private let ropeLogicalHeight: CGFloat = 11.0
    private let ropeLogicalTileWidth: CGFloat = 64.0

    public override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }

    public override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? RopeCanvasLayer {
            self.ropeSampler = other.ropeSampler
            self.curtainOpacity = other.curtainOpacity
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(in ctx: CGContext) {
        let width = bounds.width
        let height = bounds.height
        guard width > 4, height > 4, curtainOpacity > 0.01 else { return }

        let colorSpace = CGColorSpaceCreateDeviceRGB()

        // 1. Subtle warm-neutral studio gradient veil at top edge so white Polaroids & rope pop cleanly
        ctx.saveGState()
        let veilColors = [
            CGColor(red: 0.05, green: 0.04, blue: 0.03, alpha: 0.34 * curtainOpacity),
            CGColor(red: 0.05, green: 0.04, blue: 0.03, alpha: 0.14 * curtainOpacity),
            CGColor(red: 0.05, green: 0.04, blue: 0.03, alpha: 0.0)
        ] as CFArray
        if let veilGradient = CGGradient(colorsSpace: colorSpace, colors: veilColors, locations: [0.0, 0.45, 1.0]) {
            ctx.drawLinearGradient(
                veilGradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: 0, y: min(height, 260)),
                options: []
            )
        }
        ctx.restoreGState()

        guard let sampler = ropeSampler else { return }

        // Build sampled polyline along the catenary + elastic wave curve
        let step: CGFloat = 8.0
        var points: [CGPoint] = []
        points.reserveCapacity(Int(width / step) + 3)

        var x: CGFloat = -6.0
        while x <= width + 6.0 {
            points.append(CGPoint(x: x, y: sampler(x)))
            x += step
        }
        guard points.count >= 2 else { return }

        // 2. Soft drop shadow beneath the braided rope
        ctx.saveGState()
        let shadowPath = CGMutablePath()
        shadowPath.move(to: CGPoint(x: points[0].x, y: points[0].y + 5.5))
        for p in points.dropFirst() {
            shadowPath.addLine(to: CGPoint(x: p.x, y: p.y + 5.5))
        }
        ctx.addPath(shadowPath)
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        ctx.setLineWidth(7.5)
        ctx.setShadow(
            offset: CGSize(width: 0, height: 3.5),
            blur: 7.0,
            color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.38 * curtainOpacity)
        )
        ctx.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.18 * curtainOpacity))
        ctx.strokePath()
        ctx.restoreGState()

        // 3. Draw textured braided jute segments along the curve
        ctx.saveGState()
        ctx.setAlpha(curtainOpacity)
        let segmentOverlap: CGFloat = 2.0
        var arcDistance: CGFloat = 0

        for i in 0..<(points.count - 1) {
            let p0 = points[i]
            let p1 = points[i + 1]
            let dx = p1.x - p0.x
            let dy = p1.y - p0.y
            let segLen = hypot(dx, dy)
            guard segLen > 0.1 else { continue }

            let angle = atan2(dy, dx)
            let midX = (p0.x + p1.x) * 0.5
            let midY = (p0.y + p1.y) * 0.5

            // Slice sub-region of tile image continuously using arc length
            let tileStartX = arcDistance.truncatingRemainder(dividingBy: ropeLogicalTileWidth)
            let sampleWidth = min(segLen + segmentOverlap, ropeLogicalTileWidth - tileStartX)
            let pixelCrop = CGRect(
                x: tileStartX * ProceduralAssets.scale,
                y: 0,
                width: max(2.0, sampleWidth * ProceduralAssets.scale),
                height: CGFloat(ropeTile.height)
            )
            let croppedTile = ropeTile.cropping(to: pixelCrop) ?? ropeTile

            ctx.saveGState()
            ctx.translateBy(x: midX, y: midY)
            ctx.rotate(by: angle)
            // Flip Y locally inside this flipped layer so rope lighting matches top-down screen space
            ctx.scaleBy(x: 1.0, y: -1.0)
            let drawRect = CGRect(
                x: -(segLen + segmentOverlap) * 0.5,
                y: -ropeLogicalHeight * 0.5,
                width: segLen + segmentOverlap,
                height: ropeLogicalHeight
            )
            ctx.draw(croppedTile, in: drawRect)
            ctx.restoreGState()

            arcDistance += segLen
        }
        ctx.restoreGState()
    }
}

import Foundation
import AppKit
import CoreGraphics
import QuartzCore
import AVFoundation

public enum CardAction: Equatable, Sendable {
    case copy
    case reveal
    case trash
}

public final class PolaroidCardLayer: CALayer {
    public private(set) var itemID: String = ""
    public private(set) var currentItem: MediaItem?
    public private(set) var preset: CardSizePreset = .regular

    private let paperLayer = CALayer()
    private let imageWellLayer = CALayer()
    private let imageContentLayer = CALayer()
    private let placeholderTintLayer = CALayer()
    private let videoBadgeLayer = CALayer()
    private let videoPlayIconLayer = CALayer()
    private let videoDurationLayer = CATextLayer()
    private let timestampLayer = CATextLayer()
    private let actionBarLayer = CALayer()
    private let copyBtnLayer = CALayer()
    private let copyIconLayer = CALayer()
    private let revealBtnLayer = CALayer()
    private let revealIconLayer = CALayer()
    private let trashBtnLayer = CALayer()
    private let trashIconLayer = CALayer()
    private let clothespinLayer = CALayer()

    private var videoPlayerLayer: AVPlayerLayer?
    private var videoQueuePlayer: AVQueuePlayer?
    private var videoLooper: AVPlayerLooper?

    private var copyFeedbackResetTask: DispatchWorkItem?
    private var showingCopyCheckmark: Bool = false
    private var hoveredAction: CardAction?
    private var showTimestampText: Bool = true
    private var lastPinSnapProgress: CGFloat = 1.0
    private var lastAppliedHoverAmount: CGFloat = -1
    private var lastAppliedPinSnap: CGFloat = -1
    private var lastAppliedHoveredAction: CardAction?

    private static let noActions: [String: CAAction] = {
        let null = NSNull()
        return [
            "position": null,
            "bounds": null,
            "frame": null,
            "transform": null,
            "sublayerTransform": null,
            "opacity": null,
            "contents": null,
            "sublayers": null,
            "onOrderIn": null,
            "onOrderOut": null,
            "shadowOpacity": null,
            "shadowRadius": null,
            "shadowOffset": null,
            "shadowPath": null,
            "backgroundColor": null,
            "zPosition": null,
            "hidden": null,
            "anchorPoint": null
        ]
    }()

    public override func action(forKey event: String) -> (any CAAction)? {
        nil
    }

    public override init() {
        super.init()
        setupSublayers()
    }

    public override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSublayers() {
        masksToBounds = false
        actions = Self.noActions

        // Warm off-white Polaroid cardstock
        paperLayer.actions = Self.noActions
        paperLayer.allowsEdgeAntialiasing = true
        paperLayer.backgroundColor = NSColor(calibratedRed: 0.985, green: 0.976, blue: 0.957, alpha: 1.0).cgColor
        paperLayer.cornerRadius = 3.0
        paperLayer.borderWidth = 0.6
        paperLayer.borderColor = NSColor(calibratedWhite: 0.0, alpha: 0.11).cgColor
        paperLayer.shadowColor = NSColor.black.cgColor
        paperLayer.shadowOpacity = 0.28
        paperLayer.shadowRadius = 11.0
        paperLayer.shadowOffset = CGSize(width: 0, height: 6)
        addSublayer(paperLayer)

        // Photo well inside Polaroid
        imageWellLayer.actions = Self.noActions
        imageWellLayer.masksToBounds = true
        imageWellLayer.cornerRadius = 1.5
        imageWellLayer.backgroundColor = NSColor(calibratedRed: 0.91, green: 0.89, blue: 0.86, alpha: 1.0).cgColor
        imageWellLayer.borderWidth = 0.5
        imageWellLayer.borderColor = NSColor(calibratedWhite: 0.0, alpha: 0.12).cgColor
        paperLayer.addSublayer(imageWellLayer)

        placeholderTintLayer.actions = Self.noActions
        placeholderTintLayer.backgroundColor = NSColor(calibratedRed: 0.88, green: 0.86, blue: 0.82, alpha: 1.0).cgColor
        imageWellLayer.addSublayer(placeholderTintLayer)

        imageContentLayer.actions = Self.noActions
        imageContentLayer.contentsGravity = .resizeAspectFill
        imageContentLayer.minificationFilter = .trilinear
        imageContentLayer.masksToBounds = true
        imageWellLayer.addSublayer(imageContentLayer)

        // Video duration badge inside well
        videoBadgeLayer.actions = Self.noActions
        videoBadgeLayer.backgroundColor = NSColor(calibratedWhite: 0.06, alpha: 0.74).cgColor
        videoBadgeLayer.cornerRadius = 9.0
        videoBadgeLayer.borderWidth = 0.5
        videoBadgeLayer.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.18).cgColor
        videoBadgeLayer.isHidden = true
        imageWellLayer.addSublayer(videoBadgeLayer)

        videoPlayIconLayer.actions = Self.noActions
        videoPlayIconLayer.contents = ProceduralAssets.playIcon
        videoPlayIconLayer.contentsGravity = .resizeAspect
        videoBadgeLayer.addSublayer(videoPlayIconLayer)

        videoDurationLayer.actions = Self.noActions
        videoDurationLayer.font = NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .semibold)
        videoDurationLayer.fontSize = 9.5
        videoDurationLayer.foregroundColor = NSColor.white.cgColor
        videoDurationLayer.alignmentMode = .left
        videoDurationLayer.truncationMode = .none
        videoBadgeLayer.addSublayer(videoDurationLayer)

        // Hover quick-action glass pill inside image well
        actionBarLayer.actions = Self.noActions
        actionBarLayer.backgroundColor = NSColor(calibratedRed: 0.09, green: 0.08, blue: 0.075, alpha: 0.84).cgColor
        actionBarLayer.cornerRadius = 14.0
        actionBarLayer.borderWidth = 0.6
        actionBarLayer.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.20).cgColor
        actionBarLayer.shadowColor = NSColor.black.cgColor
        actionBarLayer.shadowOpacity = 0.35
        actionBarLayer.shadowRadius = 6.0
        actionBarLayer.shadowOffset = CGSize(width: 0, height: 2)
        actionBarLayer.opacity = 0
        imageWellLayer.addSublayer(actionBarLayer)

        setupActionButton(copyBtnLayer, iconLayer: copyIconLayer, icon: ProceduralAssets.copyIcon)
        setupActionButton(revealBtnLayer, iconLayer: revealIconLayer, icon: ProceduralAssets.finderIcon)
        setupActionButton(trashBtnLayer, iconLayer: trashIconLayer, icon: ProceduralAssets.trashIcon)

        // Timestamp label on Polaroid chin
        timestampLayer.actions = Self.noActions
        timestampLayer.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        timestampLayer.fontSize = 11
        timestampLayer.foregroundColor = NSColor(calibratedRed: 0.36, green: 0.32, blue: 0.28, alpha: 0.92).cgColor
        timestampLayer.alignmentMode = .center
        timestampLayer.truncationMode = .end
        paperLayer.addSublayer(timestampLayer)

        // Wooden clothespin sitting on top edge
        clothespinLayer.actions = Self.noActions
        clothespinLayer.contents = ProceduralAssets.clothespinImage
        clothespinLayer.contentsGravity = .resizeAspect
        clothespinLayer.zPosition = 20
        addSublayer(clothespinLayer)
    }

    private func setupActionButton(_ btn: CALayer, iconLayer: CALayer, icon: CGImage?) {
        btn.actions = Self.noActions
        btn.cornerRadius = 11.0
        btn.backgroundColor = NSColor.clear.cgColor
        actionBarLayer.addSublayer(btn)

        iconLayer.actions = Self.noActions
        iconLayer.contents = icon
        iconLayer.contentsGravity = .resizeAspect
        btn.addSublayer(iconLayer)
    }

    public func updateBackingScale(_ scale: CGFloat) {
        contentsScale = scale
        paperLayer.contentsScale = scale
        imageWellLayer.contentsScale = scale
        imageContentLayer.contentsScale = scale
        videoBadgeLayer.contentsScale = scale
        videoPlayIconLayer.contentsScale = scale
        videoDurationLayer.contentsScale = scale
        timestampLayer.contentsScale = scale
        actionBarLayer.contentsScale = scale
        copyBtnLayer.contentsScale = scale
        copyIconLayer.contentsScale = scale
        revealBtnLayer.contentsScale = scale
        revealIconLayer.contentsScale = scale
        trashBtnLayer.contentsScale = scale
        trashIconLayer.contentsScale = scale
        clothespinLayer.contentsScale = scale
        videoPlayerLayer?.contentsScale = scale
    }

    public func configure(item: MediaItem, preset: CardSizePreset, showTimestamp: Bool, backingScale: CGFloat) {
        let isSameItem = (self.itemID == item.id)
        if !isSameItem {
            stopVideoPreview()
            copyFeedbackResetTask?.cancel()
            showingCopyCheckmark = false
            copyIconLayer.contents = ProceduralAssets.copyIcon
            imageContentLayer.contents = nil
            placeholderTintLayer.opacity = 1.0
            lastAppliedHoverAmount = -1
            lastAppliedPinSnap = -1
            lastAppliedHoveredAction = nil
        }

        self.itemID = item.id
        self.currentItem = item
        self.preset = preset
        self.showTimestampText = showTimestamp

        updateBackingScale(backingScale)

        let size = preset.cardSize
        bounds = CGRect(origin: .zero, size: size)
        // Rope passes through the clothespin jaw 2pt below top of paper
        anchorPoint = CGPoint(x: 0.5, y: 2.0 / max(1.0, size.height))

        layoutSublayers(for: size, preset: preset, pinSnapProgress: lastPinSnapProgress)

        // Metadata labels
        timestampLayer.isHidden = !showTimestamp
        timestampLayer.fontSize = preset.fontSize
        timestampLayer.string = item.formattedTimestamp()

        if item.mediaType == .video {
            videoBadgeLayer.isHidden = false
            let durText = item.formattedDuration ?? "Video"
            videoDurationLayer.string = durText
            layoutVideoBadge(for: durText)
        } else {
            videoBadgeLayer.isHidden = true
        }
    }

    public func updateDurationLabel(_ duration: TimeInterval) {
        guard var item = currentItem, item.mediaType == .video else { return }
        item.duration = duration
        currentItem = item
        let durText = item.formattedDuration ?? "Video"
        videoDurationLayer.string = durText
        layoutVideoBadge(for: durText)
    }

    public func setThumbnail(_ image: CGImage?) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageContentLayer.contents = image
        placeholderTintLayer.opacity = (image == nil) ? 1.0 : 0.0
        CATransaction.commit()
    }

    public func applyPose(_ pose: CardRenderPose, hoveredAction: CardAction?) {
        self.hoveredAction = hoveredAction
        self.lastPinSnapProgress = pose.pinSnapProgress

        position = pose.anchorCenter
        if opacity != Float(pose.opacity) {
            opacity = Float(pose.opacity)
        }

        var transform = CATransform3DIdentity
        transform = CATransform3DRotate(transform, pose.angle, 0, 0, 1)
        transform = CATransform3DScale(transform, pose.scale, pose.scale, 1)
        self.transform = transform

        // Elevate hovered card above neighbors
        let targetZ: CGFloat = pose.isFlying ? 120 : (10.0 + pose.hoverAmount * 50.0)
        if abs(zPosition - targetZ) > 0.01 {
            zPosition = targetZ
        }

        // Only update shadow & action bar opacity when hover state actually changes (avoids shadow cache invalidation during scroll)
        if abs(pose.hoverAmount - lastAppliedHoverAmount) > 0.002 {
            lastAppliedHoverAmount = pose.hoverAmount
            paperLayer.shadowOpacity = Float(0.26 + pose.hoverAmount * 0.18)
            paperLayer.shadowRadius = 10.0 + pose.hoverAmount * 8.0
            paperLayer.shadowOffset = CGSize(width: 0, height: 5.5 + pose.hoverAmount * 5.0)
            actionBarLayer.opacity = Float(max(0.0, (pose.hoverAmount - 0.15) / 0.85))
        }

        if hoveredAction != lastAppliedHoveredAction {
            lastAppliedHoveredAction = hoveredAction
            copyBtnLayer.backgroundColor = (hoveredAction == .copy)
                ? NSColor(calibratedWhite: 1.0, alpha: 0.22).cgColor : NSColor.clear.cgColor
            revealBtnLayer.backgroundColor = (hoveredAction == .reveal)
                ? NSColor(calibratedWhite: 1.0, alpha: 0.22).cgColor : NSColor.clear.cgColor
            trashBtnLayer.backgroundColor = (hoveredAction == .trash)
                ? NSColor(calibratedRed: 1.0, green: 0.35, blue: 0.32, alpha: 0.28).cgColor : NSColor.clear.cgColor
        }

        // Clothespin vertical snap onto rope (only when pin snap progresses)
        if abs(pose.pinSnapProgress - lastAppliedPinSnap) > 0.001 {
            lastAppliedPinSnap = pose.pinSnapProgress
            layoutClothespin(pinSnapProgress: pose.pinSnapProgress)
        }
    }

    public func flashCopySuccess() {
        copyFeedbackResetTask?.cancel()
        showingCopyCheckmark = true
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        copyIconLayer.contents = ProceduralAssets.checkmarkIcon
        CATransaction.commit()

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.showingCopyCheckmark = false
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.copyIconLayer.contents = ProceduralAssets.copyIcon
            CATransaction.commit()
        }
        copyFeedbackResetTask = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    // MARK: - Inline Video Hover Preview

    public func startVideoPreviewIfNeeded() {
        guard let item = currentItem, item.mediaType == .video else { return }
        guard videoPlayerLayer == nil else { return }

        let playerItem = AVPlayerItem(url: item.url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = true
        queuePlayer.actionAtItemEnd = .none
        let looper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)

        let playerLayer = AVPlayerLayer(player: queuePlayer)
        playerLayer.actions = Self.noActions
        playerLayer.frame = imageWellLayer.bounds
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.contentsScale = contentsScale

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageWellLayer.insertSublayer(playerLayer, above: imageContentLayer)
        CATransaction.commit()

        self.videoQueuePlayer = queuePlayer
        self.videoLooper = looper
        self.videoPlayerLayer = playerLayer
        queuePlayer.play()
    }

    public func stopVideoPreview() {
        videoQueuePlayer?.pause()
        videoQueuePlayer?.removeAllItems()
        videoLooper?.disableLooping()
        videoPlayerLayer?.removeFromSuperlayer()
        videoPlayerLayer = nil
        videoQueuePlayer = nil
        videoLooper = nil
    }

    public func prepareForReuse() {
        stopVideoPreview()
        copyFeedbackResetTask?.cancel()
        copyFeedbackResetTask = nil
        itemID = ""
        currentItem = nil
        hoveredAction = nil
        lastPinSnapProgress = 1.0
        lastAppliedHoverAmount = -1
        lastAppliedPinSnap = -1
        lastAppliedHoveredAction = nil
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        removeAllAnimations()
        transform = CATransform3DIdentity
        opacity = 1.0
        zPosition = 10.0
        imageContentLayer.contents = nil
        placeholderTintLayer.opacity = 1.0
        actionBarLayer.opacity = 0
        CATransaction.commit()
    }

    // MARK: - Hit Testing

    /// Checks whether a point in `PolaroidCardLayer` local coordinates hits one of the 3 quick action buttons.
    public func actionButton(at localPoint: CGPoint) -> CardAction? {
        guard actionBarLayer.opacity > 0.35 else { return nil }
        let wellPoint = imageWellLayer.convert(localPoint, from: self)
        let barPoint = actionBarLayer.convert(wellPoint, from: imageWellLayer)
        guard actionBarLayer.bounds.contains(barPoint) else { return nil }

        if copyBtnLayer.frame.contains(barPoint) { return .copy }
        if revealBtnLayer.frame.contains(barPoint) { return .reveal }
        if trashBtnLayer.frame.contains(barPoint) { return .trash }
        return nil
    }

    // MARK: - Snapshot for Dragging

    public func makeDragPreviewImage() -> NSImage {
        let size = bounds.size
        return NSImage(size: size, flipped: true) { [weak self] _ in
            guard let self, let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let prevOpacity = self.actionBarLayer.opacity
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.actionBarLayer.opacity = 0
            CATransaction.commit()

            self.paperLayer.render(in: ctx)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            self.actionBarLayer.opacity = prevOpacity
            CATransaction.commit()
            return true
        }
    }

    // MARK: - Internal Layout

    private func layoutSublayers(for size: CGSize, preset: CardSizePreset, pinSnapProgress: CGFloat) {
        paperLayer.frame = CGRect(origin: .zero, size: size)
        paperLayer.shadowPath = CGPath(roundedRect: paperLayer.bounds, cornerWidth: 3.0, cornerHeight: 3.0, transform: nil)

        let inset = preset.imageInset
        let wellWidth = max(20, size.width - inset * 2)
        let wellHeight = max(20, size.height - preset.topMargin - preset.bottomChin)
        let wellFrame = CGRect(x: inset, y: preset.topMargin, width: wellWidth, height: wellHeight)

        imageWellLayer.frame = wellFrame
        placeholderTintLayer.frame = imageWellLayer.bounds
        imageContentLayer.frame = imageWellLayer.bounds
        videoPlayerLayer?.frame = imageWellLayer.bounds

        // Bottom chin timestamp
        let chinY = preset.topMargin + wellHeight + (preset.bottomChin - 16) * 0.5
        timestampLayer.frame = CGRect(x: inset, y: chinY, width: wellWidth, height: 16)

        // Action bar anchored near bottom center of image well
        let barW: CGFloat = 96
        let barH: CGFloat = 28
        actionBarLayer.frame = CGRect(
            x: (wellWidth - barW) * 0.5,
            y: wellHeight - barH - 8,
            width: barW,
            height: barH
        )

        let btnSize: CGFloat = 22
        let spacing: CGFloat = 7
        let startX: CGFloat = (barW - (btnSize * 3 + spacing * 2)) * 0.5
        let btnY: CGFloat = (barH - btnSize) * 0.5

        copyBtnLayer.frame = CGRect(x: startX, y: btnY, width: btnSize, height: btnSize)
        revealBtnLayer.frame = CGRect(x: startX + btnSize + spacing, y: btnY, width: btnSize, height: btnSize)
        trashBtnLayer.frame = CGRect(x: startX + (btnSize + spacing) * 2, y: btnY, width: btnSize, height: btnSize)

        let iconInset: CGFloat = 3.5
        copyIconLayer.frame = copyBtnLayer.bounds.insetBy(dx: iconInset, dy: iconInset)
        revealIconLayer.frame = revealBtnLayer.bounds.insetBy(dx: iconInset, dy: iconInset)
        trashIconLayer.frame = trashBtnLayer.bounds.insetBy(dx: iconInset, dy: iconInset)

        layoutClothespin(pinSnapProgress: pinSnapProgress)
    }

    private func layoutVideoBadge(for text: String) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9.5, weight: .semibold)
        ]
        let textWidth = ceil((text as NSString).size(withAttributes: attrs).width)
        let badgeW = max(38, textWidth + 22)
        let badgeH: CGFloat = 18
        let wellSize = imageWellLayer.bounds.size
        videoBadgeLayer.frame = CGRect(
            x: wellSize.width - badgeW - 6,
            y: 6,
            width: badgeW,
            height: badgeH
        )
        videoPlayIconLayer.frame = CGRect(x: 6, y: 4, width: 9, height: 10)
        videoDurationLayer.frame = CGRect(x: 17, y: 3, width: badgeW - 21, height: 12)
    }

    private func layoutClothespin(pinSnapProgress: CGFloat) {
        let size = bounds.size
        let pinW: CGFloat = 24
        let pinH: CGFloat = 52
        // Clamped onto rope (y = 2) with jaw covering top Polaroid border down to y = +14
        let clampedLift = (1.0 - pinSnapProgress) * 18.0
        clothespinLayer.frame = CGRect(
            x: (size.width - pinW) * 0.5,
            y: -38.0 - clampedLift,
            width: pinW,
            height: pinH
        )
        clothespinLayer.opacity = Float(min(1.0, max(0.0, pinSnapProgress * 1.4)))
    }
}

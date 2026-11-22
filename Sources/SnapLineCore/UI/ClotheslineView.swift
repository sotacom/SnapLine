import Foundation
import AppKit
import QuartzCore

@MainActor
public final class ClotheslineView: NSView, NSDraggingSource {
    public let physics = ClotheslinePhysicsEngine()

    public var onQuickLookItem: ((MediaItem, Int) -> Void)?
    public var onDoubleClickItem: ((MediaItem) -> Void)?
    public var onCardAction: ((MediaItem, CardAction, PolaroidCardLayer) -> Void)?
    public var onRequestDismiss: (() -> Void)?
    public var onHoverStateChanged: ((Bool) -> Void)?
    public var onScrollActivity: (() -> Void)?
    public var onDraggingStateChanged: ((Bool) -> Void)?
    public var onHideAnimationCompleted: (() -> Void)?
    public var onVideoDurationResolved: ((String, TimeInterval) -> Void)?

    private var items: [MediaItem] = []
    private var cachedOrderedIDs: [String] = []
    private var cardPreset: CardSizePreset = .regular
    private var showTimestamp: Bool = true
    private var sagIntensity: Double = 1.0

    private let ropeLayer = RopeCanvasLayer()
    private let cardsContainerLayer = CALayer()
    private var mountedCards: [String: PolaroidCardLayer] = [:]
    private var reusablePool: [PolaroidCardLayer] = []

    private var displayLink: CADisplayLink?
    private var trackingArea: NSTrackingArea?

    private var hoveredItemID: String?
    private var hoveredAction: CardAction?
    private var videoHoverWorkItem: DispatchWorkItem?

    private var mouseDownPoint: CGPoint = .zero
    private var dragCandidate: (item: MediaItem, index: Int, layer: PolaroidCardLayer)?
    private var pendingButtonPress: (item: MediaItem, layer: PolaroidCardLayer, action: CardAction)?
    private var clickedEmptySpace: Bool = false
    private var didStartDragging: Bool = false
    private var isHidingAnimated: Bool = false
    private var ropeNeedsRedraw: Bool = true

    public override var isFlipped: Bool { true }

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        wantsLayer = true
        layer = makeBackingLayer()
        layerContentsRedrawPolicy = .duringViewResize

        let disabledActions: [String: CAAction] = [
            "position": NSNull(),
            "bounds": NSNull(),
            "frame": NSNull(),
            "sublayers": NSNull(),
            "contents": NSNull(),
            "opacity": NSNull()
        ]
        ropeLayer.actions = disabledActions
        ropeLayer.zPosition = 1
        ropeLayer.ropeSampler = { [weak self] x in
            self?.physics.ropeY(atScreenX: x) ?? 28
        }
        layer?.addSublayer(ropeLayer)

        cardsContainerLayer.actions = disabledActions
        cardsContainerLayer.zPosition = 5
        cardsContainerLayer.masksToBounds = false
        layer?.addSublayer(cardsContainerLayer)
    }

    public override func makeBackingLayer() -> CALayer {
        let root = CALayer()
        root.isGeometryFlipped = true
        root.masksToBounds = false
        return root
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            updateBackingScales()
            ensureDisplayLink()
            wakePhysics()
        } else {
            invalidateDisplayLink()
            stopAllVideoPreviews()
        }
    }

    public override func layout() {
        super.layout()
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ropeLayer.frame = bounds
        ropeLayer.contentsScale = scale
        cardsContainerLayer.frame = bounds
        cardsContainerLayer.contentsScale = scale
        CATransaction.commit()

        physics.viewportSize = bounds.size
        physics.clampScrollBounds()
        ropeNeedsRedraw = true
        syncAndApplyFrame()
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    public override var acceptsFirstResponder: Bool { true }

    private func updateBackingScales() {
        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0
        ropeLayer.contentsScale = scale
        cardsContainerLayer.contentsScale = scale
        for card in mountedCards.values {
            card.updateBackingScale(scale)
        }
    }

    // MARK: - Public Data & Configuration

    public func updateSettings(
        cardSize: CardSizePreset,
        showTimestamp: Bool,
        ropeSagIntensity: Double
    ) {
        self.cardPreset = cardSize
        self.showTimestamp = showTimestamp
        self.sagIntensity = ropeSagIntensity

        physics.cardSize = cardSize.cardSize
        physics.slotSpacing = cardSize.slotSpacing
        physics.ropeSag = 26.0 * CGFloat(ropeSagIntensity)
        physics.clampScrollBounds()

        let scale = window?.backingScaleFactor ?? 2.0
        for (idx, item) in items.enumerated() {
            if let card = mountedCards[item.id] {
                card.configure(item: item, preset: cardPreset, showTimestamp: showTimestamp, backingScale: scale)
                if let cached = ThumbnailPipeline.shared.cachedThumbnail(for: item) {
                    card.setThumbnail(cached.image)
                }
                let pose = physics.pose(for: idx, itemID: item.id, restingAngle: item.restingAngle)
                card.applyPose(pose, hoveredAction: (hoveredItemID == item.id) ? hoveredAction : nil)
            }
        }
        ropeNeedsRedraw = true
        wakePhysics()
    }

    public func setItems(_ newItems: [MediaItem], resetScroll: Bool = false) {
        self.items = newItems
        self.cachedOrderedIDs = newItems.map(\.id)
        physics.itemCount = newItems.count
        if resetScroll {
            physics.resetScrollToNewest(animated: false)
        } else {
            physics.clampScrollBounds()
        }
        ropeNeedsRedraw = true
        syncAndApplyFrame()
    }

    public func reveal(animated: Bool, gentleBreeze: Bool = true) {
        isHidingAnimated = false
        if animated {
            if physics.curtainOffsetY >= -10 {
                physics.snapCurtainHidden()
            }
            physics.setCurtain(visible: true, animated: true)
            if gentleBreeze {
                physics.triggerGentleBreeze(visibleItems: visibleItemTuples())
            }
        } else {
            physics.setCurtain(visible: true, animated: false)
        }
        ropeNeedsRedraw = true
        syncAndApplyFrame()
        wakePhysics()
    }

    public func dismiss(animated: Bool) {
        clearHoverState()
        stopAllVideoPreviews()
        if animated {
            isHidingAnimated = true
            physics.setCurtain(visible: false, animated: true)
            ropeNeedsRedraw = true
            wakePhysics()
        } else {
            isHidingAnimated = false
            physics.snapCurtainHidden()
            syncAndApplyFrame()
            onHideAnimationCompleted?()
        }
    }

    public func presentNewCapture(
        items updatedItems: [MediaItem],
        insertedItem: MediaItem,
        insertedIndex: Int,
        revealCurtain: Bool
    ) {
        isHidingAnimated = false
        self.items = updatedItems
        self.cachedOrderedIDs = updatedItems.map(\.id)
        physics.itemCount = updatedItems.count

        let existingTuples: [(id: String, index: Int, restingAngle: CGFloat)] = updatedItems
            .enumerated()
            .filter { $0.offset != insertedIndex }
            .map { (id: $0.element.id, index: $0.offset, restingAngle: $0.element.restingAngle) }

        physics.triggerNewCapture(
            newItemID: insertedItem.id,
            newRestingAngle: insertedItem.restingAngle,
            existingItems: existingTuples,
            revealCurtain: revealCurtain
        )

        ropeNeedsRedraw = true
        syncAndApplyFrame()
        wakePhysics()
    }

    public func animateCardRemoval(item: MediaItem, index: Int) {
        let x = physics.baseX(for: index)
        physics.triggerCardRemoval(itemID: item.id, screenX: x, restingAngle: item.restingAngle)
        ropeNeedsRedraw = true
        wakePhysics()
    }

    public func screenFrame(for item: MediaItem) -> NSRect {
        guard let window, let card = mountedCards[item.id] else { return .zero }
        let windowRect = convert(card.frame, to: nil)
        return window.convertToScreen(windowRect)
    }

    public func stopAllVideoPreviews() {
        videoHoverWorkItem?.cancel()
        videoHoverWorkItem = nil
        for card in mountedCards.values {
            card.stopVideoPreview()
        }
    }

    // MARK: - CADisplayLink Loop (0% CPU when at rest)

    private func ensureDisplayLink() {
        guard displayLink == nil else { return }
        let link = self.displayLink(target: self, selector: #selector(handleDisplayLink(_:)))
        link.add(to: .main, forMode: .common)
        link.isPaused = true
        displayLink = link
    }

    private func invalidateDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func wakePhysics() {
        ensureDisplayLink()
        displayLink?.isPaused = false
    }

    @objc private func handleDisplayLink(_ link: CADisplayLink) {
        let rawDT = link.targetTimestamp - link.timestamp
        let dt = (rawDT > 0.001 && rawDT < 0.1) ? rawDT : (1.0 / 60.0)
        let stillActive = physics.step(dt: dt, orderedItemIDs: cachedOrderedIDs)

        let redrawRope = ropeNeedsRedraw || !physics.waves.isEmpty || abs(physics.curtainTargetY - physics.curtainOffsetY) > 0.5
        ropeNeedsRedraw = false

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        syncVisibleCards()
        applyAllPoses(redrawRope: redrawRope)
        CATransaction.commit()

        if !stillActive {
            link.isPaused = true
            if isHidingAnimated {
                isHidingAnimated = false
                onHideAnimationCompleted?()
            }
        }
    }

    private func syncAndApplyFrame() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        syncVisibleCards()
        applyAllPoses(redrawRope: true)
        CATransaction.commit()
    }

    // MARK: - Virtualization Pool

    private func syncVisibleCards() {
        let range = physics.visibleIndexRange(buffer: 2)
        let prefetchRange = physics.visibleIndexRange(buffer: 6)
        let keepCancelRange = physics.visibleIndexRange(buffer: 8)

        var neededIDs = Set<String>()
        neededIDs.reserveCapacity(range.count)
        for idx in range {
            neededIDs.insert(items[idx].id)
        }

        var keepIDs = Set<String>()
        keepIDs.reserveCapacity(keepCancelRange.count)
        for idx in keepCancelRange {
            keepIDs.insert(items[idx].id)
        }

        // Unmount offscreen cards (keeping any actively flying/removing card)
        let mountedKeys = Array(mountedCards.keys)
        for id in mountedKeys {
            if neededIDs.contains(id) { continue }
            if let motion = physics.cardStates[id],
               motion.flyState != nil || motion.removeProgress != nil {
                continue
            }
            if let layer = mountedCards.removeValue(forKey: id) {
                if !keepIDs.contains(id) {
                    ThumbnailPipeline.shared.cancel(for: id)
                }
                layer.prepareForReuse()
                layer.removeFromSuperlayer()
                if reusablePool.count < 20 {
                    reusablePool.append(layer)
                }
            }
        }

        let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2.0

        for idx in range {
            let item = items[idx]
            if mountedCards[item.id] != nil {
                continue
            }

            let cardLayer = reusablePool.popLast() ?? PolaroidCardLayer()
            cardLayer.configure(
                item: item,
                preset: cardPreset,
                showTimestamp: showTimestamp,
                backingScale: scale
            )
            // Apply initial pose immediately before sublayer insertion so a recycled card never flashes at a stale frame
            let initialPose = physics.pose(for: idx, itemID: item.id, restingAngle: item.restingAngle)
            cardLayer.applyPose(initialPose, hoveredAction: (hoveredItemID == item.id) ? hoveredAction : nil)

            cardsContainerLayer.addSublayer(cardLayer)
            mountedCards[item.id] = cardLayer

            if let cached = ThumbnailPipeline.shared.cachedThumbnail(for: item) {
                cardLayer.setThumbnail(cached.image)
                if let dur = cached.duration {
                    cardLayer.updateDurationLabel(dur)
                }
            } else {
                ThumbnailPipeline.shared.requestThumbnail(for: item) { [weak self, weak cardLayer] result in
                    guard let self, let cardLayer, cardLayer.itemID == item.id else { return }
                    cardLayer.setThumbnail(result?.image)
                    if let dur = result?.duration {
                        cardLayer.updateDurationLabel(dur)
                        self.onVideoDurationResolved?(item.id, dur)
                    }
                }
            }
        }

        // Prefetch upcoming thumbnails ahead of scroll
        for idx in prefetchRange where !range.contains(idx) {
            let item = items[idx]
            if ThumbnailPipeline.shared.cachedThumbnail(for: item) == nil {
                ThumbnailPipeline.shared.requestThumbnail(for: item) { _ in }
            }
        }
    }

    private func applyAllPoses(redrawRope: Bool) {
        if redrawRope {
            let curtainAlpha = max(0.0, min(1.0, 1.0 + physics.curtainOffsetY / 180.0))
            ropeLayer.curtainOpacity = curtainAlpha
            ropeLayer.setNeedsDisplay()
        }

        let range = physics.visibleIndexRange(buffer: 2)
        for idx in range {
            let item = items[idx]
            guard let cardLayer = mountedCards[item.id] else { continue }
            let pose = physics.pose(for: idx, itemID: item.id, restingAngle: item.restingAngle)
            let activeAction = (hoveredItemID == item.id) ? hoveredAction : nil
            cardLayer.applyPose(pose, hoveredAction: activeAction)
        }
    }

    private func visibleItemTuples() -> [(id: String, index: Int, restingAngle: CGFloat)] {
        let range = physics.visibleIndexRange(buffer: 2)
        return range.map { (id: items[$0].id, index: $0, restingAngle: items[$0].restingAngle) }
    }

    // MARK: - Mouse, Hover & Scroll Interactions

    public override func scrollWheel(with event: NSEvent) {
        let rawDelta: CGFloat
        if abs(event.scrollingDeltaX) >= abs(event.scrollingDeltaY) {
            rawDelta = event.scrollingDeltaX
        } else {
            rawDelta = event.scrollingDeltaY
        }

        let isPreciseOrPhased = event.hasPreciseScrollingDeltas || event.phase != [] || event.momentumPhase != []

        if isPreciseOrPhased {
            let activeGesture = (event.phase == .began || event.phase == .changed
                || event.momentumPhase == .began || event.momentumPhase == .changed)
            physics.isUserScrolling = activeGesture

            if abs(rawDelta) > 0.01 {
                physics.applyDirectScrollDelta(rawDelta)
                clearHoverState()
                onScrollActivity?()
            }
            wakePhysics()
        } else {
            physics.isUserScrolling = false
            if abs(rawDelta) > 0.01 {
                physics.scrollByWheel(deltaX: rawDelta * 36.0)
                clearHoverState()
                onScrollActivity?()
                wakePhysics()
            }
        }
    }

    public override func mouseMoved(with event: NSEvent) {
        if physics.isActivelyScrolling { return }
        let point = convert(event.locationInWindow, from: nil)
        updateHover(at: point)
    }

    public override func mouseExited(with event: NSEvent) {
        clearHoverState()
    }

    private func updateHover(at point: CGPoint) {
        let hit = hitTestCard(at: point)
        let newItemID = hit?.item.id
        let newAction: CardAction? = {
            guard let hit else { return nil }
            let localPt = hit.layer.convert(point, from: cardsContainerLayer)
            return hit.layer.actionButton(at: localPt)
        }()

        let itemChanged = (newItemID != hoveredItemID)
        let actionChanged = (newAction != hoveredAction)

        guard itemChanged || actionChanged else { return }

        if itemChanged {
            videoHoverWorkItem?.cancel()
            videoHoverWorkItem = nil
            if let oldID = hoveredItemID {
                mountedCards[oldID]?.stopVideoPreview()
            }

            hoveredItemID = newItemID
            hoveredAction = newAction

            physics.setHovered(itemID: newItemID, visibleItems: visibleItemTuples().map { ($0.id, $0.restingAngle) })
            onHoverStateChanged?(newItemID != nil)

            if let newID = newItemID,
               let cardLayer = mountedCards[newID],
               cardLayer.currentItem?.mediaType == .video {
                let work = DispatchWorkItem { [weak self, weak cardLayer] in
                    guard let self, let cardLayer, self.hoveredItemID == newID else { return }
                    cardLayer.startVideoPreviewIfNeeded()
                }
                videoHoverWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
            }

            wakePhysics()
        } else if actionChanged {
            hoveredAction = newAction
            applyAllPoses(redrawRope: false)
        }
    }

    private func clearHoverState() {
        guard hoveredItemID != nil || hoveredAction != nil else { return }
        videoHoverWorkItem?.cancel()
        videoHoverWorkItem = nil
        if let oldID = hoveredItemID {
            mountedCards[oldID]?.stopVideoPreview()
        }
        hoveredItemID = nil
        hoveredAction = nil
        physics.setHovered(itemID: nil, visibleItems: [])
        onHoverStateChanged?(false)
        wakePhysics()
    }

    public override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        mouseDownPoint = point
        didStartDragging = false
        dragCandidate = nil
        pendingButtonPress = nil
        clickedEmptySpace = false

        guard let hit = hitTestCard(at: point) else {
            clickedEmptySpace = true
            return
        }

        let localPt = hit.layer.convert(point, from: cardsContainerLayer)
        if let action = hit.layer.actionButton(at: localPt) {
            pendingButtonPress = (item: hit.item, layer: hit.layer, action: action)
        } else {
            dragCandidate = hit
        }
    }

    public override func mouseDragged(with event: NSEvent) {
        guard !didStartDragging, let candidate = dragCandidate else { return }
        let current = convert(event.locationInWindow, from: nil)
        let dist = hypot(current.x - mouseDownPoint.x, current.y - mouseDownPoint.y)
        guard dist > 6.0 else { return }

        didStartDragging = true
        onDraggingStateChanged?(true)

        let draggingItem = NSDraggingItem(pasteboardWriter: candidate.item.url as NSURL)
        let previewImage = candidate.layer.makeDragPreviewImage()
        let frameInView = candidate.layer.frame
        draggingItem.setDraggingFrame(frameInView, contents: previewImage)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }

    public override func mouseUp(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let pending = pendingButtonPress {
            let localPt = pending.layer.convert(point, from: cardsContainerLayer)
            if pending.layer.actionButton(at: localPt) == pending.action {
                onCardAction?(pending.item, pending.action, pending.layer)
            }
        } else if let candidate = dragCandidate, !didStartDragging {
            if event.clickCount >= 2 {
                onDoubleClickItem?(candidate.item)
            } else {
                onQuickLookItem?(candidate.item, candidate.index)
            }
        } else if clickedEmptySpace {
            onRequestDismiss?()
        }

        pendingButtonPress = nil
        dragCandidate = nil
        clickedEmptySpace = false
        didStartDragging = false
    }

    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 53: // ESC
            onRequestDismiss?()
        case 123: // Left arrow (into the past)
            physics.scrollStep(cardsDelta: 1)
            onScrollActivity?()
            wakePhysics()
        case 124: // Right arrow (toward newest)
            physics.scrollStep(cardsDelta: -1)
            onScrollActivity?()
            wakePhysics()
        case 49: // Spacebar -> Quick Look
            if let hoveredID = hoveredItemID,
               let idx = items.firstIndex(where: { $0.id == hoveredID }) {
                onQuickLookItem?(items[idx], idx)
            } else if !items.isEmpty {
                let lastIdx = items.count - 1
                onQuickLookItem?(items[lastIdx], lastIdx)
            }
        default:
            super.keyDown(with: event)
        }
    }

    private func hitTestCard(at pointInView: CGPoint) -> (item: MediaItem, index: Int, layer: PolaroidCardLayer)? {
        let range = physics.visibleIndexRange(buffer: 2)
        // Prioritize hovered card first if elevated, then iterate right-to-left
        if let hoveredID = hoveredItemID,
           let idx = items.firstIndex(where: { $0.id == hoveredID }),
           let cardLayer = mountedCards[hoveredID] {
            let localPt = cardLayer.convert(pointInView, from: cardsContainerLayer)
            if cardLayer.bounds.contains(localPt) {
                return (items[idx], idx, cardLayer)
            }
        }

        for idx in range.reversed() {
            let item = items[idx]
            guard let cardLayer = mountedCards[item.id] else { continue }
            let localPt = cardLayer.convert(pointInView, from: cardsContainerLayer)
            if cardLayer.bounds.contains(localPt) {
                return (item, idx, cardLayer)
            }
        }
        return nil
    }

    // MARK: - NSDraggingSource

    public func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        context == .outsideApplication ? .copy : [.copy, .move]
    }

    public func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        onDraggingStateChanged?(false)
    }

    // MARK: - Offscreen Render Helper (for verification & inspection)

    public func renderSnapshot(size: CGSize, scale: CGFloat = 2.0, backgroundColor: CGColor? = nil) -> CGImage? {
        self.frame = NSRect(origin: .zero, size: size)
        physics.viewportSize = size
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        ropeLayer.frame = CGRect(origin: .zero, size: size)
        ropeLayer.contentsScale = scale
        cardsContainerLayer.frame = CGRect(origin: .zero, size: size)
        cardsContainerLayer.contentsScale = scale
        syncVisibleCards()
        applyAllPoses(redrawRope: true)
        CATransaction.commit()

        let pxW = Int(size.width * scale)
        let pxH = Int(size.height * scale)
        guard let ctx = CGContext(
            data: nil,
            width: pxW,
            height: pxH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        // Flip CGContext top-down so root layer (isGeometryFlipped = true) renders upright
        ctx.translateBy(x: 0, y: CGFloat(pxH))
        ctx.scaleBy(x: scale, y: -scale)

        if let bg = backgroundColor {
            ctx.setFillColor(bg)
            ctx.fill(CGRect(origin: .zero, size: size))
        }

        if let rootLayer = self.layer {
            rootLayer.frame = CGRect(origin: .zero, size: size)
            rootLayer.contentsScale = scale
            rootLayer.render(in: ctx)
        }
        return ctx.makeImage()
    }
}

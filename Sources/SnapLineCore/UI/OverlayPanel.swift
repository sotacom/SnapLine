import Foundation
import AppKit
import Quartz

public final class OverlayPanel: NSPanel {
    public weak var quickLookCoordinator: QuickLookCoordinator?

    public init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 1280, height: 340),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isFloatingPanel = true
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        isMovable = false
        isReleasedWhenClosed = false
        collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]
    }

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }

    public static func activeTargetScreen() -> NSScreen? {
        let mouse = NSEvent.mouseLocation
        if let underCursor = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) {
            return underCursor
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    public func positionAtTopQuarter(of screen: NSScreen? = nil, cardPreset: CardSizePreset = .regular) {
        guard let target = screen ?? Self.activeTargetScreen() else { return }
        let visible = target.visibleFrame
        let full = target.frame

        let minHeight: CGFloat = cardPreset == .large ? 360 : 320
        let height = min(max(visible.height * 0.29, minHeight), 395)
        let topY = visible.maxY
        let originY = topY - height

        let panelFrame = NSRect(x: full.minX, y: originY, width: full.width, height: height)
        setFrame(panelFrame, display: true)
    }

    // MARK: - Quick Look Panel Control

    public override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }

    public override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        quickLookCoordinator?.beginControl(for: panel)
    }

    public override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        quickLookCoordinator?.endControl(for: panel)
    }
}

import Foundation
import AppKit
import Combine

@MainActor
public final class OverlayController: ObservableObject {
    @Published public private(set) var isVisible: Bool = false

    private let settings: AppSettings
    private let store: ScreenshotStore
    private let panel: OverlayPanel
    private let clotheslineView: ClotheslineView
    private let quickLook: QuickLookCoordinator

    private var autoHideTimer: Timer?
    private var globalMouseMonitor: Any?
    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?
    private var cancellables: Set<AnyCancellable> = []

    private var isHoveringCard: Bool = false
    private var isDraggingCard: Bool = false
    private var isQuickLookOpen: Bool = false

    public init(settings: AppSettings, store: ScreenshotStore) {
        self.settings = settings
        self.store = store
        self.panel = OverlayPanel()
        self.clotheslineView = ClotheslineView(frame: NSRect(x: 0, y: 0, width: 1280, height: 340))
        self.quickLook = QuickLookCoordinator()

        panel.quickLookCoordinator = quickLook
        panel.contentView = clotheslineView
        clotheslineView.autoresizingMask = [.width, .height]

        wireCallbacks()
        observeSettings()
    }

    private func wireCallbacks() {
        clotheslineView.updateSettings(
            cardSize: settings.cardSize,
            showTimestamp: settings.showTimestamp,
            ropeSagIntensity: settings.ropeSagIntensity
        )

        quickLook.sourceFrameProvider = { [weak self] item in
            self?.clotheslineView.screenFrame(for: item) ?? .zero
        }
        quickLook.onVisibilityChanged = { [weak self] open in
            guard let self else { return }
            self.isQuickLookOpen = open
            if open {
                self.cancelAutoHideTimer()
            } else if self.isVisible {
                self.scheduleAutoHide(graceSeconds: 3.0)
            }
        }

        clotheslineView.onQuickLookItem = { [weak self] _, index in
            guard let self else { return }
            self.quickLook.open(items: self.store.items, selectedIndex: index, ownerWindow: self.panel)
        }

        clotheslineView.onDoubleClickItem = { [weak self] item in
            guard let self else { return }
            self.store.openInDefaultApp(item)
            self.hide(animated: true)
        }

        clotheslineView.onCardAction = { [weak self] item, action, cardLayer in
            guard let self else { return }
            switch action {
            case .copy:
                if self.store.copyToPasteboard(item) {
                    cardLayer.flashCopySuccess()
                }
                self.scheduleAutoHide()
            case .reveal:
                self.store.revealInFinder(item)
                self.hide(animated: true)
            case .trash:
                try? self.store.moveToTrash(item)
                self.scheduleAutoHide()
            }
        }

        clotheslineView.onRequestDismiss = { [weak self] in
            self?.hide(animated: true)
        }

        clotheslineView.onHoverStateChanged = { [weak self] hovering in
            guard let self else { return }
            self.isHoveringCard = hovering
            if hovering {
                self.cancelAutoHideTimer()
            } else if self.isVisible {
                self.scheduleAutoHide(graceSeconds: 2.5)
            }
        }

        clotheslineView.onScrollActivity = { [weak self] in
            guard let self else { return }
            if self.isVisible {
                self.scheduleAutoHide(graceSeconds: 3.5)
            }
        }

        clotheslineView.onDraggingStateChanged = { [weak self] dragging in
            guard let self else { return }
            self.isDraggingCard = dragging
            if dragging {
                self.cancelAutoHideTimer()
            } else if self.isVisible {
                self.scheduleAutoHide(graceSeconds: 2.5)
            }
        }

        clotheslineView.onHideAnimationCompleted = { [weak self] in
            guard let self else { return }
            self.panel.orderOut(nil)
        }

        clotheslineView.onVideoDurationResolved = { [weak self] id, duration in
            self?.store.updateDuration(duration, for: id)
        }

        store.onItemsReloaded = { [weak self] in
            guard let self else { return }
            self.clotheslineView.setItems(self.store.items, resetScroll: true)
        }

        store.onNewCapture = { [weak self] item, index in
            self?.presentNewCapture(item: item, index: index)
        }

        store.onItemRemoved = { [weak self] item, index in
            guard let self else { return }
            if self.isVisible {
                self.clotheslineView.animateCardRemoval(item: item, index: index)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
                    guard let self else { return }
                    self.clotheslineView.setItems(self.store.items, resetScroll: false)
                }
            } else {
                self.clotheslineView.setItems(self.store.items, resetScroll: false)
            }
        }
    }

    private func observeSettings() {
        Publishers.CombineLatest3(
            settings.$cardSize,
            settings.$showTimestamp,
            settings.$ropeSagIntensity
        )
        .dropFirst()
        .sink { [weak self] size, showTimestamp, sag in
            guard let self else { return }
            self.clotheslineView.updateSettings(
                cardSize: size,
                showTimestamp: showTimestamp,
                ropeSagIntensity: sag
            )
            if self.isVisible {
                self.panel.positionAtTopQuarter(cardPreset: size)
            }
        }
        .store(in: &cancellables)

        settings.$autoHideDelay
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, self.isVisible else { return }
                self.scheduleAutoHide()
            }
            .store(in: &cancellables)
    }

    // MARK: - Show / Hide / New Capture

    public func toggle() {
        if isVisible {
            hide(animated: true)
        } else {
            show(animated: true)
        }
    }

    public func show(animated: Bool = true) {
        panel.positionAtTopQuarter(cardPreset: settings.cardSize)
        clotheslineView.setItems(store.items, resetScroll: true)
        panel.orderFrontRegardless()
        isVisible = true
        installDismissMonitors()
        clotheslineView.reveal(animated: animated, gentleBreeze: true)
        scheduleAutoHide()
    }

    public func hide(animated: Bool = true) {
        guard isVisible else { return }
        isVisible = false
        isHoveringCard = false
        isDraggingCard = false
        cancelAutoHideTimer()
        removeDismissMonitors()
        quickLook.closeIfOpen()
        clotheslineView.dismiss(animated: animated)
        if !animated {
            panel.orderOut(nil)
        }
    }

    public func presentNewCapture(item: MediaItem, index: Int) {
        let wasVisible = isVisible
        if !wasVisible {
            panel.positionAtTopQuarter(cardPreset: settings.cardSize)
            panel.orderFrontRegardless()
            isVisible = true
            installDismissMonitors()
        }

        clotheslineView.presentNewCapture(
            items: store.items,
            insertedItem: item,
            insertedIndex: index,
            revealCurtain: !wasVisible
        )
        scheduleAutoHide(graceSeconds: settings.autoHideDelay > 0 ? settings.autoHideDelay + 0.85 : 0)
    }

    public func playDemoAnimation() {
        guard let latest = store.items.last else {
            show(animated: true)
            return
        }
        let wasVisible = isVisible
        if !wasVisible {
            panel.positionAtTopQuarter(cardPreset: settings.cardSize)
            panel.orderFrontRegardless()
            isVisible = true
            installDismissMonitors()
        }

        // Briefly treat previous items as existing and animate latest card flying onto rope
        clotheslineView.presentNewCapture(
            items: store.items,
            insertedItem: latest,
            insertedIndex: store.items.count - 1,
            revealCurtain: !wasVisible
        )
        scheduleAutoHide(graceSeconds: settings.autoHideDelay > 0 ? settings.autoHideDelay + 0.85 : 0)
    }

    // MARK: - Auto-Hide & Dismiss Monitors

    private func scheduleAutoHide(graceSeconds: Double? = nil) {
        cancelAutoHideTimer()
        let configured = settings.autoHideDelay
        guard configured > 0 else { return }
        guard !isHoveringCard && !isDraggingCard && !isQuickLookOpen else { return }

        let delay = graceSeconds ?? configured
        guard delay > 0 else { return }

        autoHideTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isVisible else { return }
                guard !self.isHoveringCard && !self.isDraggingCard && !self.isQuickLookOpen else { return }
                self.hide(animated: true)
            }
        }
    }

    private func cancelAutoHideTimer() {
        autoHideTimer?.invalidate()
        autoHideTimer = nil
    }

    private func installDismissMonitors() {
        removeDismissMonitors()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isVisible else { return }
                guard !self.isQuickLookOpen && !self.isDraggingCard else { return }

                let mouseLoc = NSEvent.mouseLocation
                // Let clicks inside panel frame be handled by ClotheslineView (cards vs empty space)
                if NSMouseInRect(mouseLoc, self.panel.frame, false) {
                    return
                }
                // Avoid double-toggle when clicking the menu bar itself
                if let screen = self.panel.screen, mouseLoc.y >= screen.visibleFrame.maxY {
                    return
                }
                self.hide(animated: true)
            }
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                Task { @MainActor [weak self] in
                    guard let self, self.isVisible, !self.isQuickLookOpen else { return }
                    self.hide(animated: true)
                }
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isVisible, !self.isQuickLookOpen else { return event }
            if event.keyCode == 53 {
                self.hide(animated: true)
                return nil
            }
            return event
        }
    }

    private func removeDismissMonitors() {
        if let m = globalMouseMonitor {
            NSEvent.removeMonitor(m)
            globalMouseMonitor = nil
        }
        if let m = globalKeyMonitor {
            NSEvent.removeMonitor(m)
            globalKeyMonitor = nil
        }
        if let m = localKeyMonitor {
            NSEvent.removeMonitor(m)
            localKeyMonitor = nil
        }
    }
}

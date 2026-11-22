import Foundation
import AppKit
@preconcurrency import Quartz

@MainActor
public final class QuickLookCoordinator: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public var items: [MediaItem] = []
    public var sourceFrameProvider: ((MediaItem) -> NSRect)?
    public var onVisibilityChanged: ((Bool) -> Void)?

    public private(set) var isOpen: Bool = false

    public func open(items: [MediaItem], selectedIndex: Int, ownerWindow: NSWindow) {
        guard !items.isEmpty else { return }
        self.items = items
        let clampedIndex = max(0, min(items.count - 1, selectedIndex))

        guard let panel = QLPreviewPanel.shared() else { return }
        NSApp.activate(ignoringOtherApps: true)
        ownerWindow.makeKey()

        panel.dataSource = self
        panel.delegate = self
        panel.currentPreviewItemIndex = clampedIndex
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)

        isOpen = true
        onVisibilityChanged?(true)
    }

    public func closeIfOpen() {
        guard QLPreviewPanel.sharedPreviewPanelExists(),
              let panel = QLPreviewPanel.shared(),
              panel.isVisible else {
            return
        }
        panel.orderOut(nil)
        isOpen = false
        onVisibilityChanged?(false)
    }

    public func beginControl(for panel: QLPreviewPanel) {
        panel.dataSource = self
        panel.delegate = self
        isOpen = true
        onVisibilityChanged?(true)
    }

    public func endControl(for panel: QLPreviewPanel) {
        panel.dataSource = nil
        panel.delegate = nil
        isOpen = false
        onVisibilityChanged?(false)
    }

    // MARK: - QLPreviewPanelDataSource

    public nonisolated func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        MainActor.assumeIsolated {
            items.count
        }
    }

    public nonisolated func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> (any QLPreviewItem)! {
        MainActor.assumeIsolated {
            guard index >= 0, index < items.count else { return nil }
            return items[index].url as NSURL
        }
    }

    // MARK: - QLPreviewPanelDelegate

    public nonisolated func previewPanel(_ panel: QLPreviewPanel!, sourceFrameOnScreenFor item: (any QLPreviewItem)!) -> NSRect {
        MainActor.assumeIsolated {
            guard let url = item?.previewItemURL,
                  let match = items.first(where: { $0.url == url }),
                  let rect = sourceFrameProvider?(match) else {
                return .zero
            }
            return rect
        }
    }

    public nonisolated func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        false
    }
}

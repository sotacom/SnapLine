import Foundation
import AppKit
import SwiftUI

@MainActor
public final class MenuBarController: NSObject, NSMenuDelegate {
    private let settings: AppSettings
    private let store: ScreenshotStore
    private let overlayController: OverlayController

    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private let settingsViewModel = SettingsViewModel()
    private var settingsWindow: NSWindow?

    public init(settings: AppSettings, store: ScreenshotStore, overlayController: OverlayController) {
        self.settings = settings
        self.store = store
        self.overlayController = overlayController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = ProceduralAssets.makeMenuBarIcon()
            button.imagePosition = .imageOnly
            button.toolTip = "SnapLine — Dây treo Screenshot"
        }

        menu.delegate = self
        statusItem.menu = menu
        rebuildMenu()
    }

    public func menuNeedsUpdate(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let toggleTitle = overlayController.isVisible
            ? "Ẩn dây treo ảnh (\(settings.hotKey.displayName))"
            : "Hiện dây treo ảnh (\(settings.hotKey.displayName))"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(handleToggleOverlay), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)

        let demoItem = NSMenuItem(title: "Thử hiệu ứng chụp mới (Demo)", action: #selector(handlePlayDemo), keyEquivalent: "")
        demoItem.target = self
        menu.addItem(demoItem)

        menu.addItem(NSMenuItem.separator())

        let folderName = settings.watchedFolderURL.lastPathComponent
        let infoItem = NSMenuItem(
            title: "Thư mục: \(folderName) (\(store.items.count) mục)",
            action: nil,
            keyEquivalent: ""
        )
        infoItem.isEnabled = false
        menu.addItem(infoItem)

        let openFolderItem = NSMenuItem(title: "Mở thư mục trong Finder", action: #selector(handleOpenFolderInFinder), keyEquivalent: "")
        openFolderItem.target = self
        menu.addItem(openFolderItem)

        let chooseFolderItem = NSMenuItem(title: "Đổi thư mục lưu screenshot...", action: #selector(handleChooseFolder), keyEquivalent: "")
        chooseFolderItem.target = self
        menu.addItem(chooseFolderItem)

        menu.addItem(NSMenuItem.separator())

        let instantItem = NSMenuItem(
            title: "Chụp xong hiện ngay (Tắt thumbnail macOS)",
            action: #selector(handleToggleInstantCapture),
            keyEquivalent: ""
        )
        instantItem.target = self
        instantItem.state = !SystemScreenshotConfig.isFloatingThumbnailEnabled() ? .on : .off
        menu.addItem(instantItem)

        let settingsMenuItem = NSMenuItem(title: "Cài đặt...", action: #selector(handleOpenSettings), keyEquivalent: ",")
        settingsMenuItem.target = self
        menu.addItem(settingsMenuItem)

        let quitItem = NSMenuItem(title: "Thoát SnapLine", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func handleToggleOverlay() {
        overlayController.toggle()
    }

    @objc private func handlePlayDemo() {
        overlayController.playDemoAnimation()
    }

    @objc private func handleOpenFolderInFinder() {
        NSWorkspace.shared.open(settings.watchedFolderURL)
    }

    @objc private func handleToggleInstantCapture() {
        let currentlyInstant = !SystemScreenshotConfig.isFloatingThumbnailEnabled()
        let nextInstant = !currentlyInstant
        do {
            try SystemScreenshotConfig.setFloatingThumbnailEnabled(!nextInstant)
            settingsViewModel.refresh()
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    @objc public func handleChooseFolder() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.title = "Chọn thư mục lưu Screenshot"
        panel.message = "SnapLine sẽ theo dõi và treo các ảnh chụp / video quay màn hình từ thư mục này."
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = settings.watchedFolderURL

        guard panel.runModal() == .OK, let selectedURL = panel.url else { return }
        do {
            try settings.updateWatchedFolder(selectedURL, syncToSystemIfEnabled: true)
            store.reloadFolder(url: selectedURL)
        } catch {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }

    @objc public func handleOpenSettings() {
        settingsViewModel.refresh()
        if let existing = settingsWindow {
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let view = SettingsView(
            settings: settings,
            store: store,
            viewModel: settingsViewModel,
            onPickFolder: { [weak self] in
                self?.handleChooseFolder()
            },
            onPlayDemo: { [weak self] in
                self?.overlayController.playDemoAnimation()
            }
        )

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Cài đặt SnapLine"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        window.center()

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        self.settingsWindow = window
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }
}

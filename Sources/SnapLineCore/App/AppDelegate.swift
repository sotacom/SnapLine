import Foundation
import AppKit
import Combine

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: AppSettings!
    private var store: ScreenshotStore!
    private var overlayController: OverlayController!
    private var menuBarController: MenuBarController!
    private var hotKeyManager: GlobalHotKeyManager!
    private var cancellables: Set<AnyCancellable> = []

    public func applicationDidFinishLaunching(_ notification: Notification) {
        if ensureSingleInstance() == false {
            NSApp.terminate(nil)
            return
        }

        NSApp.setActivationPolicy(.accessory)

        // Pre-warm procedural @2x assets (~5ms)
        _ = ProceduralAssets.braidedRopeTile
        _ = ProceduralAssets.clothespinImage

        settings = AppSettings()
        store = ScreenshotStore(watchEnabled: true)
        overlayController = OverlayController(settings: settings, store: store)
        menuBarController = MenuBarController(
            settings: settings,
            store: store,
            overlayController: overlayController
        )
        hotKeyManager = GlobalHotKeyManager()

        registerHotKey(settings.hotKey)
        settings.$hotKey
            .dropFirst()
            .sink { [weak self] newPreset in
                self?.registerHotKey(newPreset)
            }
            .store(in: &cancellables)

        store.reloadFolder(url: settings.watchedFolderURL)

        let launchedInBackground = CommandLine.arguments.contains("--background")
        if !launchedInBackground {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.overlayController.show(animated: true)
            }
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        hotKeyManager?.unregister()
        store?.stopWatching()
    }

    private func registerHotKey(_ preset: HotKeyPreset) {
        hotKeyManager.register(preset: preset) { [weak self] in
            self?.overlayController.toggle()
        }
    }

    private func ensureSingleInstance() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier, !bundleID.isEmpty else {
            return true
        }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
            .filter { $0.processIdentifier != currentPID }
        return others.isEmpty
    }
}

public enum SnapLineApplication {
    @MainActor
    public static func run() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}

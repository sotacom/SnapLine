import Foundation
import AppKit
import AVFoundation

@MainActor
public final class ScreenshotStore: ObservableObject {
    @Published public private(set) var items: [MediaItem] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var currentFolderURL: URL?

    public var onNewCapture: ((MediaItem, Int) -> Void)?
    public var onItemsReloaded: (() -> Void)?
    public var onItemRemoved: ((MediaItem, Int) -> Void)?

    private let watcher: FolderWatcher?
    private let watchEnabled: Bool
    private var loadGeneration: Int = 0

    public init(watchEnabled: Bool = true) {
        self.watchEnabled = watchEnabled
        self.watcher = watchEnabled ? FolderWatcher() : nil
        setupWatcherCallbacks()
    }

    private func setupWatcherCallbacks() {
        watcher?.onItemReady = { [weak self] url in
            Task { @MainActor [weak self] in
                await self?.handleReadyFile(url: url)
            }
        }
        watcher?.onDirectoryMutated = { [weak self] in
            Task { @MainActor [weak self] in
                self?.reconcileDeletions()
            }
        }
    }

    public func reloadFolder(url: URL) {
        let standardized = url.standardizedFileURL
        currentFolderURL = standardized
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true

        if watchEnabled {
            watcher?.stop()
        }

        Task.detached(priority: .userInitiated) {
            let scanned = Self.scanDirectory(url: standardized)
            await MainActor.run { [weak self] in
                guard let self, self.loadGeneration == generation else { return }
                self.items = scanned
                self.isLoading = false
                if self.watchEnabled {
                    self.watcher?.start(watching: standardized)
                }
                self.onItemsReloaded?()
            }
        }
    }

    public func stopWatching() {
        watcher?.stop()
    }

    public nonisolated static func scanDirectory(url: URL) -> [MediaItem] {
        let fm = FileManager.default
        let keys: [URLResourceKey] = [
            .creationDateKey,
            .contentModificationDateKey,
            .isRegularFileKey,
            .isDirectoryKey,
            .isHiddenKey,
            .fileSizeKey
        ]

        guard let entries = try? fm.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsSubdirectoryDescendants]
        ) else {
            return []
        }

        var collected: [MediaItem] = []
        collected.reserveCapacity(entries.count)

        for entry in entries {
            let name = entry.lastPathComponent
            if name.isEmpty || name.hasPrefix(".") {
                continue
            }
            guard let values = try? entry.resourceValues(forKeys: Set(keys)) else {
                continue
            }
            if values.isHidden == true || values.isDirectory == true {
                continue
            }
            guard let mediaType = MediaItem.mediaType(for: entry) else {
                continue
            }
            let created = values.creationDate ?? values.contentModificationDate ?? Date.distantPast
            let modified = values.contentModificationDate ?? created
            let size = Int64(values.fileSize ?? 0)
            let item = MediaItem(
                url: entry,
                createdAt: created,
                modifiedAt: modified,
                fileSize: size,
                mediaType: mediaType
            )
            collected.append(item)
        }

        collected.sort(by: MediaItem.chronologicalCompare)
        return collected
    }

    public func handleReadyFile(url: URL) async {
        let standardized = url.standardizedFileURL
        if let folder = currentFolderURL,
           standardized.deletingLastPathComponent().path != folder.standardizedFileURL.path {
            return
        }

        let canonicalID = standardized.path
        if items.contains(where: { $0.id == canonicalID }) {
            return
        }

        guard let item = await Self.buildMediaItem(for: standardized) else {
            return
        }

        // Re-check after await to prevent duplicate insertion.
        if items.contains(where: { $0.id == canonicalID }) {
            return
        }

        let insertIndex = insertChronologically(item)
        onNewCapture?(item, insertIndex)
    }

    /// Inserts an item synchronously in chronological order and returns its index.
    @discardableResult
    public func insertChronologically(_ item: MediaItem) -> Int {
        if let existing = items.firstIndex(where: { $0.id == item.id }) {
            return existing
        }
        let insertIndex = items.firstIndex(where: { !MediaItem.chronologicalCompare($0, item) }) ?? items.count
        items.insert(item, at: insertIndex)
        return insertIndex
    }

    public func updateDuration(_ duration: TimeInterval, for id: String) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        if items[idx].duration != duration {
            items[idx].duration = duration
        }
    }

    public func reconcileDeletions() {
        let fm = FileManager.default
        var removedPairs: [(MediaItem, Int)] = []
        for (index, item) in items.enumerated().reversed() {
            if !fm.fileExists(atPath: item.url.path) {
                removedPairs.append((item, index))
                items.remove(at: index)
            }
        }
        for (item, index) in removedPairs {
            onItemRemoved?(item, index)
        }
    }

    // MARK: - Item Actions

    @discardableResult
    public func copyToPasteboard(_ item: MediaItem) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.mediaType {
        case .image:
            if let image = NSImage(contentsOf: item.url) {
                return pasteboard.writeObjects([image, item.url as NSURL])
            }
            return pasteboard.writeObjects([item.url as NSURL])
        case .video:
            return pasteboard.writeObjects([item.url as NSURL])
        }
    }

    public func revealInFinder(_ item: MediaItem) {
        NSWorkspace.shared.activateFileViewerSelecting([item.url])
    }

    public func openInDefaultApp(_ item: MediaItem) {
        NSWorkspace.shared.open(item.url)
    }

    public func moveToTrash(_ item: MediaItem) throws {
        try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            let removed = items.remove(at: index)
            onItemRemoved?(removed, index)
        }
    }

    private nonisolated static func buildMediaItem(for url: URL) async -> MediaItem? {
        guard let mediaType = MediaItem.mediaType(for: url) else { return nil }
        let keys: Set<URLResourceKey> = [.creationDateKey, .contentModificationDateKey, .fileSizeKey, .isDirectoryKey]
        guard let values = try? url.resourceValues(forKeys: keys), values.isDirectory != true else {
            return nil
        }
        let created = values.creationDate ?? values.contentModificationDate ?? Date()
        let modified = values.contentModificationDate ?? created
        let size = Int64(values.fileSize ?? 0)

        var duration: TimeInterval?
        if mediaType == .video {
            let asset = AVURLAsset(url: url)
            if let loaded = try? await asset.load(.duration), loaded.isValid {
                duration = loaded.seconds
            }
        }

        return MediaItem(
            url: url,
            createdAt: created,
            modifiedAt: modified,
            fileSize: size,
            mediaType: mediaType,
            duration: duration
        )
    }
}

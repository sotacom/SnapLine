import Foundation
import AppKit
import CoreServices
import ImageIO
import AVFoundation

public final class FolderWatcher: @unchecked Sendable {
    public var onItemReady: (@MainActor (URL) -> Void)?
    public var onDirectoryMutated: (@MainActor () -> Void)?

    private let queue = DispatchQueue(label: "com.snapline.folderwatcher", qos: .utility)
    private var watchedURL: URL?
    private var eventStream: FSEventStreamRef?
    private var dirSource: DispatchSourceFileSystemObject?
    private var dirFD: Int32 = -1
    private var mountObserver: NSObjectProtocol?
    private var inFlightPaths: Set<String> = []
    private var pendingMutationWorkItem: DispatchWorkItem?

    public init() {}

    deinit {
        stopSync()
    }

    public func start(watching url: URL) {
        let standardized = url.standardizedFileURL
        queue.async { [weak self] in
            self?.stopOnQueue()
            self?.watchedURL = standardized
            self?.startStreamsOnQueue(for: standardized)
        }
    }

    public func stop() {
        queue.async { [weak self] in
            self?.stopOnQueue()
        }
    }

    private func stopSync() {
        queue.sync {
            stopOnQueue()
        }
    }

    private func stopOnQueue() {
        pendingMutationWorkItem?.cancel()
        pendingMutationWorkItem = nil
        inFlightPaths.removeAll()

        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }

        if let source = dirSource {
            source.cancel()
            dirSource = nil
        } else if dirFD >= 0 {
            close(dirFD)
            dirFD = -1
        }

        if let observer = mountObserver {
            NotificationCenter.default.removeObserver(observer)
            mountObserver = nil
        }
    }

    private func startStreamsOnQueue(for url: URL) {
        startFSEvents(for: url)
        startDirectoryVnodeSource(for: url)
        observeVolumeMountIfNeeded(for: url)
    }

    private func startFSEvents(for url: URL) {
        let pathsToWatch = [url.path] as CFArray
        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let flags = FSEventStreamCreateFlags(
            kFSEventStreamCreateFlagFileEvents |
            kFSEventStreamCreateFlagNoDefer |
            kFSEventStreamCreateFlagUseCFTypes
        )

        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, _ in
                guard let info = clientCallBackInfo else { return }
                let watcher = Unmanaged<FolderWatcher>.fromOpaque(info).takeUnretainedValue()
                guard let cfArray = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }
                watcher.handleFSEvents(paths: cfArray, flags: eventFlags, count: numEvents)
            },
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.015,
            flags
        ) else {
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        if FSEventStreamStart(stream) {
            eventStream = stream
        } else {
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }

    private func startDirectoryVnodeSource(for url: URL) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        dirFD = fd
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.scheduleMutationNotification()
        }
        source.setCancelHandler { [weak self] in
            if let fd = self?.dirFD, fd >= 0 {
                close(fd)
                self?.dirFD = -1
            }
        }
        source.resume()
        dirSource = source
    }

    private func observeVolumeMountIfNeeded(for url: URL) {
        mountObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didMountNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            guard let self else { return }
            self.queue.asyncAfter(deadline: .now() + 0.4) {
                guard let current = self.watchedURL else { return }
                if self.eventStream == nil && FileManager.default.fileExists(atPath: current.path) {
                    self.startStreamsOnQueue(for: current)
                    self.scheduleMutationNotification()
                }
            }
        }
    }

    private func handleFSEvents(paths: [String], flags: UnsafePointer<FSEventStreamEventFlags>, count: Int) {
        guard let watchedURL else { return }
        let watchedPath = watchedURL.standardizedFileURL.path
        var sawDeletionOrRename = false

        for i in 0..<min(count, paths.count) {
            let rawPath = paths[i]
            let fileURL = URL(fileURLWithPath: rawPath).standardizedFileURL
            let parentPath = fileURL.deletingLastPathComponent().path
            if parentPath != watchedPath {
                continue
            }

            let name = fileURL.lastPathComponent
            if name.isEmpty || name.hasPrefix(".") {
                continue
            }

            let eventFlag = flags[i]
            let removed = (eventFlag & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved)) != 0
            let renamed = (eventFlag & FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed)) != 0

            if removed || renamed {
                sawDeletionOrRename = true
            }

            if MediaItem.isSupportedFile(url: fileURL) && FileManager.default.fileExists(atPath: fileURL.path) {
                enqueueReadinessCheck(for: fileURL)
            }
        }

        if sawDeletionOrRename {
            scheduleMutationNotification()
        }
    }

    private func scheduleMutationNotification() {
        pendingMutationWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let callback = self.onDirectoryMutated
            Task { @MainActor in
                callback?()
            }
        }
        pendingMutationWorkItem = work
        queue.asyncAfter(deadline: .now() + 0.18, execute: work)
    }

    private func enqueueReadinessCheck(for url: URL) {
        let canonical = url.standardizedFileURL.path
        guard !inFlightPaths.contains(canonical) else { return }
        inFlightPaths.insert(canonical)

        let mediaType = MediaItem.mediaType(for: url) ?? .image
        Task.detached(priority: .utility) { [weak self] in
            let ready = await Self.waitUntilFileReady(url: url, mediaType: mediaType)
            guard let self else { return }
            self.queue.async {
                self.inFlightPaths.remove(canonical)
            }
            if ready {
                let callback = self.onItemReady
                await MainActor.run {
                    callback?(url.standardizedFileURL)
                }
            }
        }
    }

    private static func waitUntilFileReady(url: URL, mediaType: MediaType) async -> Bool {
        let maxAttempts = mediaType == .video ? 120 : 35
        let pollNanoseconds: UInt64 = mediaType == .video ? 120_000_000 : 40_000_000

        var previousSize: Int64 = -1
        var stableCount = 0

        for attempt in 0..<maxAttempts {
            if Task.isCancelled { return false }
            guard FileManager.default.fileExists(atPath: url.path) else {
                return false
            }

            let size = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.int64Value ?? 0

            // Fast-path on attempt 0 for atomically renamed screenshots: if image stream is already complete, trigger immediately (<15ms)
            if mediaType == .image && attempt == 0 && size > 0 && isCompleteImage(at: url) {
                return true
            }

            if size > 0 && size == previousSize {
                stableCount += 1
            } else {
                stableCount = 0
            }
            previousSize = size

            if stableCount >= 1 {
                switch mediaType {
                case .image:
                    if isCompleteImage(at: url) {
                        return true
                    }
                case .video:
                    if await isVideoPlayable(at: url) {
                        return true
                    }
                }
            }

            try? await Task.sleep(nanoseconds: pollNanoseconds)
        }
        return false
    }

    private static func isCompleteImage(at url: URL) -> Bool {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return false }
        let status = CGImageSourceGetStatusAtIndex(source, 0)
        guard status == .statusComplete else { return false }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return false }
        let width = props[kCGImagePropertyPixelWidth] as? Int ?? 0
        let height = props[kCGImagePropertyPixelHeight] as? Int ?? 0
        return width > 0 && height > 0
    }

    private static func isVideoPlayable(at url: URL) async -> Bool {
        let asset = AVURLAsset(url: url)
        do {
            let isPlayable = try await asset.load(.isPlayable)
            let duration = try await asset.load(.duration)
            return isPlayable && duration.isValid && duration.seconds > 0
        } catch {
            return false
        }
    }
}

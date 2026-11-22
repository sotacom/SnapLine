import Foundation
import CoreGraphics
import ImageIO
import AVFoundation
import UniformTypeIdentifiers

public struct ThumbnailResult: @unchecked Sendable {
    public let image: CGImage
    public let duration: TimeInterval?

    public init(image: CGImage, duration: TimeInterval? = nil) {
        self.image = image
        self.duration = duration
    }
}

private final class ThumbnailCacheEntry: NSObject {
    let result: ThumbnailResult
    init(result: ThumbnailResult) {
        self.result = result
    }
}

public final class ThumbnailPipeline: @unchecked Sendable {
    public static let shared = ThumbnailPipeline()

    private let memoryCache = NSCache<NSString, ThumbnailCacheEntry>()
    private let stateLock = NSLock()
    private var activeTasks: [String: Task<Void, Never>] = [:]
    private var pendingQueue: [(item: MediaItem, maxPixelSize: Int, completion: @MainActor (ThumbnailResult?) -> Void)] = []
    private var runningCount: Int = 0
    private let maxConcurrentTasks: Int = 6
    private let diskCacheDir: URL

    public init(diskCacheDirectory: URL? = nil) {
        memoryCache.countLimit = 160
        memoryCache.totalCostLimit = 48 * 1024 * 1024

        if let diskCacheDirectory {
            self.diskCacheDir = diskCacheDirectory
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? FileManager.default.temporaryDirectory
            self.diskCacheDir = caches
                .appendingPathComponent("com.snapline.app", isDirectory: true)
                .appendingPathComponent("thumbnails", isDirectory: true)
        }
        try? FileManager.default.createDirectory(at: diskCacheDir, withIntermediateDirectories: true)
    }

    public func cachedThumbnail(for item: MediaItem) -> ThumbnailResult? {
        let key = cacheKey(for: item) as NSString
        return memoryCache.object(forKey: key)?.result
    }

    public func requestThumbnail(
        for item: MediaItem,
        maxPixelSize: Int = 380,
        completion: @MainActor @escaping (ThumbnailResult?) -> Void
    ) {
        let key = cacheKey(for: item) as NSString
        if let hit = memoryCache.object(forKey: key) {
            Task { @MainActor in
                completion(hit.result)
            }
            return
        }

        stateLock.lock()
        let alreadyActive = activeTasks[item.id] != nil
        if alreadyActive {
            stateLock.unlock()
            return
        }
        pendingQueue.append((item: item, maxPixelSize: maxPixelSize, completion: completion))
        stateLock.unlock()

        drainQueue()
    }

    public func cancel(for itemID: String) {
        stateLock.lock()
        pendingQueue.removeAll { $0.item.id == itemID }
        let task = activeTasks.removeValue(forKey: itemID)
        stateLock.unlock()
        task?.cancel()
    }

    public func cancelAll() {
        stateLock.lock()
        pendingQueue.removeAll()
        let tasks = activeTasks.values
        activeTasks.removeAll()
        stateLock.unlock()
        for task in tasks {
            task.cancel()
        }
    }

    public func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    private func drainQueue() {
        while true {
            stateLock.lock()
            guard runningCount < maxConcurrentTasks, !pendingQueue.isEmpty else {
                stateLock.unlock()
                return
            }
            let job = pendingQueue.removeFirst()
            if activeTasks[job.item.id] != nil {
                stateLock.unlock()
                continue
            }
            runningCount += 1

            let task = Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                let result = await self.loadOrGenerate(item: job.item, maxPixelSize: job.maxPixelSize)
                let cancelled = Task.isCancelled

                self.stateLock.withLock {
                    self.activeTasks.removeValue(forKey: job.item.id)
                    self.runningCount = max(0, self.runningCount - 1)
                }

                if !cancelled {
                    if let result {
                        let cost = result.image.bytesPerRow * result.image.height
                        self.memoryCache.setObject(
                            ThumbnailCacheEntry(result: result),
                            forKey: self.cacheKey(for: job.item) as NSString,
                            cost: cost
                        )
                    }
                    await MainActor.run {
                        job.completion(result)
                    }
                }
                self.drainQueue()
            }

            activeTasks[job.item.id] = task
            stateLock.unlock()
        }
    }

    private func loadOrGenerate(item: MediaItem, maxPixelSize: Int) async -> ThumbnailResult? {
        if Task.isCancelled { return nil }

        let diskURL = diskCacheFileURL(for: item)
        if item.mediaType == .image, let cachedImage = loadDiskImage(at: diskURL) {
            return ThumbnailResult(image: cachedImage, duration: item.duration)
        }

        switch item.mediaType {
        case .image:
            guard let cgImage = generateImageThumbnail(url: item.url, maxPixelSize: maxPixelSize) else {
                return nil
            }
            saveDiskThumbnail(cgImage, to: diskURL)
            return ThumbnailResult(image: cgImage, duration: nil)

        case .video:
            if let cachedImage = loadDiskImage(at: diskURL), let knownDuration = item.duration {
                return ThumbnailResult(image: cachedImage, duration: knownDuration)
            }
            let generated = await generateVideoThumbnail(url: item.url, maxPixelSize: maxPixelSize)
            if let generated {
                saveDiskThumbnail(generated.image, to: diskURL)
            }
            return generated
        }
    }

    private func generateImageThumbnail(url: URL, maxPixelSize: Int) -> CGImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
            return nil
        }
        let thumbOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, thumbOptions as CFDictionary)
    }

    private func generateVideoThumbnail(url: URL, maxPixelSize: Int) async -> ThumbnailResult? {
        let asset = AVURLAsset(url: url)
        var durationSeconds: TimeInterval?
        if let duration = try? await asset.load(.duration), duration.isValid, duration.seconds.isFinite {
            durationSeconds = duration.seconds
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: maxPixelSize, height: maxPixelSize)

        let captureTimeSec = min(0.25, max(0.0, (durationSeconds ?? 0) * 0.25))
        let cmTime = CMTime(seconds: captureTimeSec, preferredTimescale: 600)

        do {
            let (cgImage, _) = try await generator.image(at: cmTime)
            return ThumbnailResult(image: cgImage, duration: durationSeconds)
        } catch {
            return nil
        }
    }

    private func loadDiskImage(at url: URL) -> CGImage? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let opts: [CFString: Any] = [kCGImageSourceShouldCacheImmediately: true]
        return CGImageSourceCreateImageAtIndex(source, 0, opts as CFDictionary)
    }

    private func saveDiskThumbnail(_ image: CGImage, to url: URL) {
        guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil) else {
            return
        }
        let opts: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.86]
        CGImageDestinationAddImage(dest, image, opts as CFDictionary)
        CGImageDestinationFinalize(dest)
        pruneDiskCacheIfNeeded()
    }

    private func pruneDiskCacheIfNeeded() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: diskCacheDir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ), files.count > 340 else {
            return
        }
        let sorted = files.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
            return lDate < rDate
        }
        for stale in sorted.prefix(files.count - 260) {
            try? fm.removeItem(at: stale)
        }
    }

    private func cacheKey(for item: MediaItem) -> String {
        "\(item.id)|\(Int(item.modifiedAt.timeIntervalSince1970))|\(item.fileSize)"
    }

    private func diskCacheFileURL(for item: MediaItem) -> URL {
        let raw = cacheKey(for: item)
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        for byte in raw.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        return diskCacheDir.appendingPathComponent(String(format: "%016llx.jpg", hash))
    }
}

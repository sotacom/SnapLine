import Foundation
import CoreGraphics

public enum MediaType: String, Sendable, Codable {
    case image
    case video
}

public struct MediaItem: Identifiable, Equatable, Hashable, Sendable {
    public let id: String
    public let url: URL
    public let fileName: String
    public let createdAt: Date
    public let modifiedAt: Date
    public let fileSize: Int64
    public let mediaType: MediaType
    public let restingAngle: CGFloat
    public var duration: TimeInterval?

    public static let imageExtensions: Set<String> = [
        "png", "jpg", "jpeg", "heic", "tiff", "tif", "webp", "gif", "bmp"
    ]

    public static let videoExtensions: Set<String> = [
        "mov", "mp4", "m4v"
    ]

    public init(
        url: URL,
        createdAt: Date,
        modifiedAt: Date,
        fileSize: Int64,
        mediaType: MediaType,
        duration: TimeInterval? = nil
    ) {
        let standardized = url.standardizedFileURL
        self.url = standardized
        self.id = standardized.path
        self.fileName = standardized.lastPathComponent
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.fileSize = fileSize
        self.mediaType = mediaType
        self.restingAngle = Self.deterministicRestingAngle(for: standardized.lastPathComponent)
        self.duration = duration
    }

    public var sortDate: Date {
        if createdAt.timeIntervalSince1970 > 1_000 {
            return createdAt
        }
        return modifiedAt
    }

    public static func mediaType(for url: URL) -> MediaType? {
        let name = url.lastPathComponent
        if name.isEmpty || name.hasPrefix(".") || name == ".DS_Store" {
            return nil
        }
        let ext = url.pathExtension.lowercased()
        if imageExtensions.contains(ext) {
            return .image
        }
        if videoExtensions.contains(ext) {
            return .video
        }
        return nil
    }

    public static func isSupportedFile(url: URL) -> Bool {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
            return false
        }
        return mediaType(for: url) != nil
    }

    public static func isSupportedFileName(_ fileName: String, isDirectory: Bool = false) -> Bool {
        if isDirectory || fileName.isEmpty || fileName.hasPrefix(".") {
            return false
        }
        let ext = URL(fileURLWithPath: fileName).pathExtension.lowercased()
        return imageExtensions.contains(ext) || videoExtensions.contains(ext)
    }

    public static func chronologicalCompare(_ lhs: MediaItem, _ rhs: MediaItem) -> Bool {
        let lDate = lhs.sortDate
        let rDate = rhs.sortDate
        if lDate != rDate {
            return lDate < rDate
        }
        return lhs.fileName.localizedStandardCompare(rhs.fileName) == .orderedAscending
    }

    /// Stable FNV-1a 64-bit hash mapped deterministically into [-0.055, +0.055] radians (~±3.15°).
    public static func deterministicRestingAngle(for fileName: String) -> CGFloat {
        var hash: UInt64 = 14_695_981_039_346_656_037
        let prime: UInt64 = 1_099_511_628_211
        for byte in fileName.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }
        let unit = Double(hash % 10_001) / 10_000.0 // 0.0 ... 1.0
        let angle = (unit * 2.0 - 1.0) * 0.055
        return CGFloat(angle)
    }

    public func formattedTimestamp(relativeTo now: Date = Date(), calendar: Calendar = .current) -> String {
        let date = sortDate
        if calendar.isDate(date, inSameDayAs: now) {
            return Self.timeFormatter.string(from: date)
        }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) {
            return "Hôm qua · \(Self.timeFormatter.string(from: date))"
        }
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        if sameYear {
            let day = calendar.component(.day, from: date)
            let month = calendar.component(.month, from: date)
            return "\(day) Th\(month)"
        }
        return Self.shortDateFormatter.string(from: date)
    }

    public var formattedDuration: String? {
        guard let duration, duration.isFinite, duration > 0 else { return nil }
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private static let timeFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt
    }()

    private static let shortDateFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "dd/MM/yy"
        return fmt
    }()
}

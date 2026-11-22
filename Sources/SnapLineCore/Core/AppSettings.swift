import Foundation
import CoreGraphics
import Carbon.HIToolbox

public enum CardSizePreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case compact
    case regular
    case large

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .compact: return "Nhỏ gọn"
        case .regular: return "Vừa (Mặc định)"
        case .large: return "Lớn"
        }
    }

    public var cardSize: CGSize {
        switch self {
        case .compact: return CGSize(width: 148, height: 166)
        case .regular: return CGSize(width: 174, height: 194)
        case .large: return CGSize(width: 206, height: 228)
        }
    }

    public var slotSpacing: CGFloat {
        switch self {
        case .compact: return 174
        case .regular: return 204
        case .large: return 240
        }
    }

    public var imageInset: CGFloat {
        switch self {
        case .compact: return 8
        case .regular: return 9
        case .large: return 10
        }
    }

    public var bottomChin: CGFloat {
        switch self {
        case .compact: return 28
        case .regular: return 32
        case .large: return 36
        }
    }

    public var topMargin: CGFloat {
        switch self {
        case .compact: return 14
        case .regular: return 16
        case .large: return 18
        }
    }

    public var fontSize: CGFloat {
        switch self {
        case .compact: return 10
        case .regular: return 11
        case .large: return 12
        }
    }
}

public enum HotKeyPreset: String, CaseIterable, Codable, Identifiable, Sendable {
    case cmdShiftL
    case optShiftS
    case ctrlOptS
    case cmdShiftK

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cmdShiftL: return "⌘⇧L"
        case .optShiftS: return "⌥⇧S"
        case .ctrlOptS: return "⌃⌥S"
        case .cmdShiftK: return "⌘⇧K"
        }
    }

    public var keyCode: UInt32 {
        switch self {
        case .cmdShiftL: return UInt32(kVK_ANSI_L)
        case .optShiftS: return UInt32(kVK_ANSI_S)
        case .ctrlOptS: return UInt32(kVK_ANSI_S)
        case .cmdShiftK: return UInt32(kVK_ANSI_K)
        }
    }

    public var carbonModifiers: UInt32 {
        switch self {
        case .cmdShiftL: return UInt32(cmdKey | shiftKey)
        case .optShiftS: return UInt32(optionKey | shiftKey)
        case .ctrlOptS: return UInt32(controlKey | optionKey)
        case .cmdShiftK: return UInt32(cmdKey | shiftKey)
        }
    }
}

public enum SystemConfigError: LocalizedError {
    case commandFailed(String, Int32, String)

    public var errorDescription: String? {
        switch self {
        case let .commandFailed(cmd, status, output):
            return "Lệnh '\(cmd)' thất bại (mã \(status)): \(output)"
        }
    }
}

public struct SystemScreenshotConfig {
    private static let suiteName = "com.apple.screencapture"

    public static func defaultDesktopURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
    }

    public static func readSystemLocation() -> URL {
        if let suite = UserDefaults(suiteName: suiteName),
           let raw = suite.string(forKey: "location"),
           !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let expanded = (raw as NSString).expandingTildeInPath
            let url = URL(fileURLWithPath: expanded, isDirectory: true).standardizedFileURL
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        return defaultDesktopURL()
    }

    public static func writeSystemLocation(_ url: URL) throws {
        let path = url.standardizedFileURL.path
        try runCommand("/usr/bin/defaults", arguments: ["write", suiteName, "location", path])
        reloadScreenshotServices()
    }

    public static func isFloatingThumbnailEnabled() -> Bool {
        if let suite = UserDefaults(suiteName: suiteName),
           let value = suite.object(forKey: "show-thumbnail") as? Bool {
            return value
        }
        return true
    }

    public static func setFloatingThumbnailEnabled(_ enabled: Bool) throws {
        try runCommand(
            "/usr/bin/defaults",
            arguments: ["write", suiteName, "show-thumbnail", "-bool", enabled ? "true" : "false"]
        )
        reloadScreenshotServices()
    }

    private static func reloadScreenshotServices() {
        DistributedNotificationCenter.default().post(
            name: NSNotification.Name("com.apple.screencapture.prefschanged"),
            object: nil
        )
        _ = try? runCommand("/usr/bin/killall", arguments: ["screencaptureui"])
        _ = try? runCommand("/usr/bin/killall", arguments: ["SystemUIServer"])
    }

    @discardableResult
    private static func runCommand(_ executablePath: String, arguments: [String]) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = arguments

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        if process.terminationStatus != 0 {
            throw SystemConfigError.commandFailed(executablePath, process.terminationStatus, output)
        }
        return output
    }
}

public enum LaunchAgentManager {
    public static let label = "com.snapline.app"

    public static var plistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist", isDirectory: false)
    }

    public static var isEnabled: Bool {
        FileManager.default.fileExists(atPath: plistURL.path)
    }

    public static func setEnabled(_ enabled: Bool) throws {
        let fm = FileManager.default
        if !enabled {
            if fm.fileExists(atPath: plistURL.path) {
                try fm.removeItem(at: plistURL)
            }
            return
        }

        guard let executablePath = Bundle.main.executablePath else { return }
        let launchAgentsDir = plistURL.deletingLastPathComponent()
        if !fm.fileExists(atPath: launchAgentsDir.path) {
            try fm.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        }

        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": [executablePath, "--background"],
            "RunAtLoad": true,
            "KeepAlive": false
        ]
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: plistURL, options: .atomic)
    }
}

@MainActor
public final class AppSettings: ObservableObject {
    private enum Keys {
        static let watchedFolderPath = "snapline.watchedFolderPath"
        static let syncSystemLocation = "snapline.syncSystemLocation"
        static let autoHideDelay = "snapline.autoHideDelay"
        static let cardSize = "snapline.cardSize"
        static let showTimestamp = "snapline.showTimestamp"
        static let ropeSagIntensity = "snapline.ropeSagIntensity"
        static let hotKey = "snapline.hotKey"
    }

    private let defaults: UserDefaults

    @Published public var watchedFolderURL: URL {
        didSet {
            defaults.set(watchedFolderURL.standardizedFileURL.path, forKey: Keys.watchedFolderPath)
        }
    }

    @Published public var syncSystemLocation: Bool {
        didSet {
            defaults.set(syncSystemLocation, forKey: Keys.syncSystemLocation)
        }
    }

    /// Auto-hide delay in seconds; 0 means stay open until manual dismiss.
    @Published public var autoHideDelay: Double {
        didSet {
            defaults.set(autoHideDelay, forKey: Keys.autoHideDelay)
        }
    }

    @Published public var cardSize: CardSizePreset {
        didSet {
            defaults.set(cardSize.rawValue, forKey: Keys.cardSize)
        }
    }

    @Published public var showTimestamp: Bool {
        didSet {
            defaults.set(showTimestamp, forKey: Keys.showTimestamp)
        }
    }

    @Published public var ropeSagIntensity: Double {
        didSet {
            defaults.set(ropeSagIntensity, forKey: Keys.ropeSagIntensity)
        }
    }

    @Published public var hotKey: HotKeyPreset {
        didSet {
            defaults.set(hotKey.rawValue, forKey: Keys.hotKey)
        }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let savedPath = defaults.string(forKey: Keys.watchedFolderPath),
           !savedPath.isEmpty {
            self.watchedFolderURL = URL(fileURLWithPath: savedPath, isDirectory: true).standardizedFileURL
        } else {
            self.watchedFolderURL = SystemScreenshotConfig.readSystemLocation()
        }

        if defaults.object(forKey: Keys.syncSystemLocation) != nil {
            self.syncSystemLocation = defaults.bool(forKey: Keys.syncSystemLocation)
        } else {
            self.syncSystemLocation = true
        }

        if defaults.object(forKey: Keys.autoHideDelay) != nil {
            self.autoHideDelay = defaults.double(forKey: Keys.autoHideDelay)
        } else {
            self.autoHideDelay = 6.0
        }

        if let rawSize = defaults.string(forKey: Keys.cardSize),
           let preset = CardSizePreset(rawValue: rawSize) {
            self.cardSize = preset
        } else {
            self.cardSize = .regular
        }

        if defaults.object(forKey: Keys.showTimestamp) != nil {
            self.showTimestamp = defaults.bool(forKey: Keys.showTimestamp)
        } else {
            self.showTimestamp = true
        }

        if defaults.object(forKey: Keys.ropeSagIntensity) != nil {
            self.ropeSagIntensity = max(0.3, min(1.6, defaults.double(forKey: Keys.ropeSagIntensity)))
        } else {
            self.ropeSagIntensity = 1.0
        }

        if let rawKey = defaults.string(forKey: Keys.hotKey),
           let preset = HotKeyPreset(rawValue: rawKey) {
            self.hotKey = preset
        } else {
            self.hotKey = .cmdShiftL
        }
    }

    public func updateWatchedFolder(_ url: URL, syncToSystemIfEnabled: Bool = true) throws {
        let standardized = url.standardizedFileURL
        watchedFolderURL = standardized
        if syncToSystemIfEnabled && syncSystemLocation {
            try SystemScreenshotConfig.writeSystemLocation(standardized)
        }
    }
}

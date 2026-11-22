import Foundation
import CoreGraphics
import SnapLineCore

@MainActor
enum MediaStoreTests {
    static func register(into runner: TestRunner) {
        runner.add("MediaStore.scanFiltersHiddenAndNonMediaAndSortsChronologically") {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("SnapLineTests-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let now = Date()
            let files: [(name: String, date: Date)] = [
                ("Screenshot 03.png", now.addingTimeInterval(-10)),
                ("Screenshot 01.png", now.addingTimeInterval(-300)),
                ("Recording 02.mov", now.addingTimeInterval(-120)),
                ("Photo 04.heic", now.addingTimeInterval(-2)),
                (".Screenshot hidden.png", now),
                (".DS_Store", now),
                ("readme.txt", now)
            ]

            for entry in files {
                let fileURL = tempDir.appendingPathComponent(entry.name)
                try Data("test".utf8).write(to: fileURL)
                try FileManager.default.setAttributes(
                    [.creationDate: entry.date, .modificationDate: entry.date],
                    ofItemAtPath: fileURL.path
                )
            }

            let subDir = tempDir.appendingPathComponent("FakeImage.png", isDirectory: true)
            try FileManager.default.createDirectory(at: subDir, withIntermediateDirectories: true)

            let scanned = ScreenshotStore.scanDirectory(url: tempDir)
            try expect(scanned.map(\.fileName) == [
                "Screenshot 01.png",
                "Recording 02.mov",
                "Screenshot 03.png",
                "Photo 04.heic"
            ], "Unexpected scanned order/list: \(scanned.map(\.fileName))")
            try expect(scanned[0].mediaType == .image)
            try expect(scanned[1].mediaType == .video)
        }

        runner.add("MediaItem.deterministicRestingAngleBounds") {
            let names = ["Screenshot 2026-11-22 at 10.00.01.png", "Screen Recording.mov", "a.jpg", "b.heic"]
            for name in names {
                let a1 = MediaItem.deterministicRestingAngle(for: name)
                let a2 = MediaItem.deterministicRestingAngle(for: name)
                try expectApprox(a1, a2, accuracy: 0.000001)
                try expect(abs(a1) <= 0.0551)
            }
        }

        runner.add("AppSettings.persistenceWithoutMutatingSystemDefaults") {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("SnapLineSettings-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            let suiteName = "com.snapline.tests.\(UUID().uuidString)"
            guard let customDefaults = UserDefaults(suiteName: suiteName) else {
                throw TestFailure(message: "Failed to allocate custom UserDefaults")
            }
            defer { customDefaults.removePersistentDomain(forName: suiteName) }

            let settings = AppSettings(defaults: customDefaults)
            settings.autoHideDelay = 10.0
            settings.cardSize = .large
            settings.showTimestamp = false
            settings.hotKey = .optShiftS
            try settings.updateWatchedFolder(tempDir, syncToSystemIfEnabled: false)

            let reloaded = AppSettings(defaults: customDefaults)
            try expect(abs(reloaded.autoHideDelay - 10.0) < 0.001)
            try expect(reloaded.cardSize == .large)
            try expect(!reloaded.showTimestamp)
            try expect(reloaded.hotKey == .optShiftS)
            try expect(reloaded.watchedFolderURL.standardizedFileURL.path == tempDir.standardizedFileURL.path)
        }
    }
}

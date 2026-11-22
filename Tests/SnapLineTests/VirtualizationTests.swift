import Foundation
import CoreGraphics
import SnapLineCore

@MainActor
enum VirtualizationTests {
    static func register(into runner: TestRunner) {
        runner.add("Virtualization.largeLibraryVisibleRangeBoundsAndWindowSize") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1440, height: 340),
                itemCount: 2000,
                cardSize: CGSize(width: 174, height: 194),
                slotSpacing: 204
            )

            let newestRange = engine.visibleIndexRange(buffer: 2)
            try expect(newestRange.upperBound == 2000)
            try expect(newestRange.lowerBound >= 1984)
            try expect(newestRange.count <= 16)

            engine.scrollBy(deltaX: engine.maxScrollOffset, isDirectGesture: false)
            let oldestRange = engine.visibleIndexRange(buffer: 2)
            try expect(oldestRange.lowerBound == 0)
            try expect(oldestRange.count <= 16)

            engine.resetScrollToNewest(animated: false)
            engine.scrollBy(deltaX: engine.maxScrollOffset * 0.5, isDirectGesture: false)
            let midRange = engine.visibleIndexRange(buffer: 2)
            try expect(midRange.lowerBound > 0)
            try expect(midRange.upperBound < 2000)
            try expect(midRange.count <= 16)
        }

        runner.add("Virtualization.emptyAndSingleItemRanges") {
            let engine = ClotheslinePhysicsEngine(viewportSize: CGSize(width: 1200, height: 320), itemCount: 0)
            try expect(engine.visibleIndexRange(buffer: 2).isEmpty)

            engine.itemCount = 1
            let single = engine.visibleIndexRange(buffer: 2)
            try expect(single == 0..<1)
        }
    }
}

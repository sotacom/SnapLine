import Foundation
import CoreGraphics
import SnapLineCore

@MainActor
enum PhysicsEngineTests {
    static func register(into runner: TestRunner) {
        runner.add("PhysicsEngine.catenaryCurveSymmetryAndSag") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1200, height: 320),
                ropeAnchorY: 24,
                ropeSag: 28
            )
            let leftY = engine.ropeY(atScreenX: 150)
            let rightY = engine.ropeY(atScreenX: 1050)
            let centerY = engine.ropeY(atScreenX: 600)
            let edgeY = engine.ropeY(atScreenX: 0)

            try expectApprox(leftY, rightY, accuracy: 0.001, "Catenary curve should be symmetric")
            try expect(centerY > leftY, "Center should sag lower than side")
            try expectApprox(edgeY, 24, accuracy: 0.001)
            try expectApprox(centerY, 52, accuracy: 0.001)
        }

        runner.add("PhysicsEngine.ropeWaveInjectionAndDecayToRest") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1200, height: 320),
                ropeAnchorY: 24,
                ropeSag: 24
            )
            let baselineY = engine.ropeY(atScreenX: 900)
            engine.injectRopeWave(at: 900, amplitude: 12.0, damping: 4.5, frequency: 18.0, spread: 180.0)

            _ = engine.step(dt: 0.025)
            let displacedY = engine.ropeY(atScreenX: 900)
            try expect(abs(displacedY - baselineY) > 1.0, "Wave should displace rope")

            var active = true
            for _ in 0..<240 {
                active = engine.step(dt: 1.0 / 60.0)
            }
            try expect(!active, "Engine should reach idle rest state for 0% CPU")
            try expect(engine.waves.isEmpty, "Waves should dissipate")
            try expectApprox(engine.ropeY(atScreenX: 900), baselineY, accuracy: 0.01)
        }

        runner.add("PhysicsEngine.newCaptureFourStageChoreography") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1440, height: 340),
                itemCount: 4,
                cardSize: CGSize(width: 174, height: 194),
                slotSpacing: 204
            )

            let existingIDs = ["c0", "c1", "c2"]
            let newID = "c3"
            let orderedIDs = existingIDs + [newID]
            let existingTuples = existingIDs.enumerated().map {
                (id: $0.element, index: $0.offset, restingAngle: CGFloat(0.02))
            }

            engine.snapCurtainHidden()
            engine.triggerNewCapture(
                newItemID: newID,
                newRestingAngle: -0.02,
                existingItems: existingTuples,
                revealCurtain: true
            )

            try expectApprox(engine.cardStates["c2"]?.shiftOffsetX ?? 0, 204, accuracy: 0.5)
            let earlyPose = engine.pose(for: 3, itemID: newID, restingAngle: -0.02)
            try expect(earlyPose.opacity < 0.001, "New card waits for shift start")
            try expect(earlyPose.isFlying, "New card starts in flight state")

            // Stage 1 (t=0.10s): Breeze swings existing cards gently before shift begins
            for _ in 0..<6 {
                _ = engine.step(dt: 1.0 / 60.0, orderedItemIDs: orderedIDs)
            }
            try expect(abs((engine.cardStates["c2"]?.angle ?? 0.02) - 0.02) > 0.0005, "Existing card should swing in Stage 1")
            try expectApprox(engine.cardStates["c2"]?.shiftOffsetX ?? 0, 204, accuracy: 0.5)

            // Stage 2 & 3 (t=0.35s): Old cards shift left; new card flies up
            for _ in 0..<15 {
                _ = engine.step(dt: 1.0 / 60.0, orderedItemIDs: orderedIDs)
            }
            try expect((engine.cardStates["c2"]?.shiftOffsetX ?? 999) < 180, "Old card shifts left")
            let midFlyPose = engine.pose(for: 3, itemID: newID, restingAngle: -0.02)
            try expect(midFlyPose.isFlying)
            try expect(midFlyPose.opacity > 0.2)

            // Stage 4 (t=0.70s): Landed, clothespin snapping, elastic rope wave active
            for _ in 0..<21 {
                _ = engine.step(dt: 1.0 / 60.0, orderedItemIDs: orderedIDs)
            }
            let landedPose = engine.pose(for: 3, itemID: newID, restingAngle: -0.02)
            try expect(!landedPose.isFlying, "New card should have landed")
            try expect(!engine.waves.isEmpty, "Landing should induce elastic rope wave")

            // Settle completely to 0% CPU rest state
            var stillActive = true
            for _ in 0..<300 {
                stillActive = engine.step(dt: 1.0 / 60.0, orderedItemIDs: orderedIDs)
            }
            try expect(!stillActive, "Engine must converge to rest")
            let settledPose = engine.pose(for: 3, itemID: newID, restingAngle: -0.02)
            try expectApprox(settledPose.pinSnapProgress, 1.0, accuracy: 0.001)
            try expectApprox(settledPose.angle, -0.02, accuracy: 0.002)
        }

        runner.add("PhysicsEngine.scrollBoundsAndRubberBandReturn") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1000, height: 320),
                itemCount: 20,
                cardSize: CGSize(width: 174, height: 194),
                slotSpacing: 204
            )
            try expect(engine.maxScrollOffset > 2000)

            engine.isUserScrolling = true
            engine.scrollBy(deltaX: -120, isDirectGesture: true)
            try expect(engine.scrollOffset < 0)

            engine.isUserScrolling = false
            for _ in 0..<180 {
                _ = engine.step(dt: 1.0 / 60.0)
            }
            try expectApprox(engine.scrollOffset, 0, accuracy: 0.5)
        }

        runner.add("PhysicsEngine.directTrackpadScrollTracksOneToOneWithoutCompounding") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1440, height: 340),
                itemCount: 30,
                cardSize: CGSize(width: 174, height: 194),
                slotSpacing: 204
            )

            engine.isUserScrolling = true
            var expectedOffset: CGFloat = 0
            for _ in 0..<20 {
                let delta: CGFloat = 24.0
                expectedOffset += delta
                engine.applyDirectScrollDelta(delta)
                _ = engine.step(dt: 1.0 / 60.0)
                try expect(abs(engine.scrollSwayAngle) <= 0.10, "Cohesive scroll sway must remain subtle (<=0.10 rad)")
            }
            engine.isUserScrolling = false
            try expectApprox(engine.scrollOffset, expectedOffset, accuracy: 0.01, "Trackpad scroll should track 1:1 without velocity compounding")

            // Should stay near expectedOffset without flying further from double momentum, and settle sway to 0
            var active = true
            for _ in 0..<180 {
                active = engine.step(dt: 1.0 / 60.0)
            }
            try expect(!active, "Engine should settle cleanly to rest after trackpad scroll ends")
            try expectApprox(engine.scrollOffset, expectedOffset, accuracy: 0.5)
            try expectApprox(engine.scrollSwayAngle, 0, accuracy: 0.002)
        }

        runner.add("PhysicsEngine.discreteMouseWheelSmoothlyGlidesToTarget") {
            let engine = ClotheslinePhysicsEngine(
                viewportSize: CGSize(width: 1440, height: 340),
                itemCount: 30,
                cardSize: CGSize(width: 174, height: 194),
                slotSpacing: 204
            )

            engine.scrollByWheel(deltaX: 120)
            engine.scrollByWheel(deltaX: 120)
            try expectApprox(engine.scrollTargetOffset ?? 0, 240, accuracy: 0.01)

            var active = true
            for _ in 0..<180 {
                active = engine.step(dt: 1.0 / 60.0)
            }
            try expect(!active)
            try expectApprox(engine.scrollOffset, 240, accuracy: 0.5)
            try expectApprox(engine.scrollSwayAngle, 0, accuracy: 0.002)
        }
    }
}

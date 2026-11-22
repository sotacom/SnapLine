import Foundation
import CoreGraphics

public struct RopeWave: Equatable, Sendable {
    public var originX: CGFloat
    public var amplitude: CGFloat
    public var age: CGFloat
    public var damping: CGFloat
    public var frequency: CGFloat
    public var spread: CGFloat

    public init(
        originX: CGFloat,
        amplitude: CGFloat,
        age: CGFloat = 0,
        damping: CGFloat = 4.4,
        frequency: CGFloat = 19.0,
        spread: CGFloat = 190.0
    ) {
        self.originX = originX
        self.amplitude = amplitude
        self.age = age
        self.damping = damping
        self.frequency = frequency
        self.spread = spread
    }

    public func displacement(at x: CGFloat) -> CGFloat {
        guard age >= 0 else { return 0 }
        let dx = x - originX
        let spatial = exp(-(dx * dx) / (2.0 * spread * spread))
        let temporal = amplitude * exp(-damping * age) * sin(frequency * age)
        return temporal * spatial
    }

    public var currentPeakAmplitude: CGFloat {
        abs(amplitude) * exp(-damping * max(0, age))
    }
}

public struct FlyInState: Equatable, Sendable {
    public var elapsed: CGFloat
    public var duration: CGFloat
    public var startPoint: CGPoint
    public var targetX: CGFloat

    public init(elapsed: CGFloat, duration: CGFloat, startPoint: CGPoint, targetX: CGFloat) {
        self.elapsed = elapsed
        self.duration = duration
        self.startPoint = startPoint
        self.targetX = targetX
    }

    public var progress: CGFloat {
        guard elapsed >= 0, duration > 0 else { return 0 }
        return min(1.0, elapsed / duration)
    }

    public var isStarted: Bool { elapsed >= 0 }
    public var isCompleted: Bool { elapsed >= duration }
}

public struct CardMotionState: Equatable, Sendable {
    public var angle: CGFloat
    public var angularVelocity: CGFloat
    public var restingAngle: CGFloat
    public var shiftOffsetX: CGFloat
    public var shiftVelocityX: CGFloat
    public var shiftDelayRemaining: CGFloat
    public var hoverAmount: CGFloat
    public var isHovered: Bool
    public var flyState: FlyInState?
    public var pinSnapProgress: CGFloat
    public var pinSnapElapsed: CGFloat
    public var isPinSnapping: Bool
    public var removeProgress: CGFloat?

    public init(
        restingAngle: CGFloat = 0,
        angle: CGFloat? = nil
    ) {
        self.restingAngle = restingAngle
        self.angle = angle ?? restingAngle
        self.angularVelocity = 0
        self.shiftOffsetX = 0
        self.shiftVelocityX = 0
        self.shiftDelayRemaining = 0
        self.hoverAmount = 0
        self.isHovered = false
        self.flyState = nil
        self.pinSnapProgress = 1.0
        self.pinSnapElapsed = 0
        self.isPinSnapping = false
        self.removeProgress = nil
    }
}

public struct CardRenderPose: Equatable, Sendable {
    public var anchorCenter: CGPoint
    public var angle: CGFloat
    public var scale: CGFloat
    public var opacity: CGFloat
    public var pinSnapProgress: CGFloat
    public var hoverAmount: CGFloat
    public var isFlying: Bool
    public var removeProgress: CGFloat
}

public final class ClotheslinePhysicsEngine {
    public var viewportSize: CGSize
    public var itemCount: Int
    public var cardSize: CGSize
    public var slotSpacing: CGFloat
    public var ropeAnchorY: CGFloat
    public var ropeSag: CGFloat
    public var leftPadding: CGFloat
    public var rightPadding: CGFloat

    // Scroll state (0 = newest at rightmost edge; increases as user scrolls back in time)
    public private(set) var scrollOffset: CGFloat = 0
    public private(set) var scrollVelocity: CGFloat = 0
    public var isUserScrolling: Bool = false
    public private(set) var scrollTargetOffset: CGFloat?

    // Cohesive scroll sway (gentle lean while gliding horizontally, prevents per-card overlap)
    public private(set) var scrollSwayAngle: CGFloat = 0
    private var scrollSwayVelocity: CGFloat = 0
    private var smoothedScrollVelocity: CGFloat = 0

    public var isActivelyScrolling: Bool {
        isUserScrolling || abs(smoothedScrollVelocity) > 45 || abs(scrollVelocity) > 45 || scrollTargetOffset != nil
    }

    // Curtain reveal/dismiss vertical offset
    public private(set) var curtainOffsetY: CGFloat = 0
    public private(set) var curtainTargetY: CGFloat = 0
    private var curtainVelocityY: CGFloat = 0

    // Dynamic waves on rope
    public private(set) var waves: [RopeWave] = []

    // Per-card physics states keyed by MediaItem.id
    public private(set) var cardStates: [String: CardMotionState] = [:]

    // Track previous scroll offset to derive smooth cohesive sway velocity
    private var lastScrollOffsetForAccel: CGFloat = 0

    public init(
        viewportSize: CGSize = CGSize(width: 1440, height: 340),
        itemCount: Int = 0,
        cardSize: CGSize = CGSize(width: 174, height: 194),
        slotSpacing: CGFloat = 204,
        ropeAnchorY: CGFloat = 44,
        ropeSag: CGFloat = 26,
        leftPadding: CGFloat = 54,
        rightPadding: CGFloat = 54
    ) {
        self.viewportSize = viewportSize
        self.itemCount = itemCount
        self.cardSize = cardSize
        self.slotSpacing = slotSpacing
        self.ropeAnchorY = ropeAnchorY
        self.ropeSag = ropeSag
        self.leftPadding = leftPadding
        self.rightPadding = rightPadding
    }

    // MARK: - Layout & Virtualization

    public var rightAnchorX: CGFloat {
        max(leftPadding + cardSize.width * 0.5, viewportSize.width - rightPadding - cardSize.width * 0.5)
    }

    public var maxScrollOffset: CGFloat {
        guard itemCount > 1 else { return 0 }
        let oldestXWhenZero = rightAnchorX - CGFloat(itemCount - 1) * slotSpacing
        let leftLimit = leftPadding + cardSize.width * 0.5
        return max(0, leftLimit - oldestXWhenZero)
    }

    public func baseX(for index: Int) -> CGFloat {
        guard itemCount > 0 else { return rightAnchorX }
        return rightAnchorX - CGFloat(itemCount - 1 - index) * slotSpacing + scrollOffset
    }

    public func visibleIndexRange(buffer: Int = 2) -> Range<Int> {
        guard itemCount > 0, viewportSize.width > 0, slotSpacing > 1 else {
            return 0..<0
        }
        let minVisibleX = -slotSpacing * CGFloat(buffer)
        let maxVisibleX = viewportSize.width + slotSpacing * CGFloat(buffer)
        let nMinus1 = CGFloat(itemCount - 1)

        let rawStart = floor((minVisibleX - rightAnchorX - scrollOffset) / slotSpacing + nMinus1)
        let rawEnd = ceil((maxVisibleX - rightAnchorX - scrollOffset) / slotSpacing + nMinus1)

        let start = max(0, min(itemCount, Int(rawStart)))
        let end = max(start, min(itemCount, Int(rawEnd) + 1))
        return start..<end
    }

    // MARK: - Rope Geometry

    public func ropeY(atScreenX x: CGFloat, includeCurtain: Bool = true) -> CGFloat {
        let width = max(1.0, viewportSize.width)
        let u = (2.0 * x / width) - 1.0
        let catenary = ropeAnchorY + ropeSag * max(0.0, 1.0 - u * u)

        var waveDelta: CGFloat = 0
        for wave in waves {
            waveDelta += wave.displacement(at: x)
        }
        let curtain = includeCurtain ? curtainOffsetY : 0
        return catenary + waveDelta + curtain
    }

    public func ropeSlopeAngle(atScreenX x: CGFloat) -> CGFloat {
        let delta: CGFloat = 4.0
        let y1 = ropeY(atScreenX: x - delta)
        let y2 = ropeY(atScreenX: x + delta)
        return atan2(y2 - y1, delta * 2.0)
    }

    public func injectRopeWave(
        at x: CGFloat,
        amplitude: CGFloat = 10.0,
        damping: CGFloat = 4.4,
        frequency: CGFloat = 19.0,
        spread: CGFloat = 190.0
    ) {
        waves.append(RopeWave(
            originX: x,
            amplitude: amplitude,
            age: 0,
            damping: damping,
            frequency: frequency,
            spread: spread
        ))
    }

    // MARK: - Curtain & Scroll Controls

    public func setCurtain(visible: Bool, animated: Bool) {
        let target: CGFloat = visible ? 0 : -260
        curtainTargetY = target
        if !animated {
            curtainOffsetY = target
            curtainVelocityY = 0
        } else if visible && curtainOffsetY < -10 {
            // Start cleanly from above if previously hidden
            curtainVelocityY = 120
        }
    }

    public func snapCurtainHidden() {
        curtainOffsetY = -260
        curtainTargetY = -260
        curtainVelocityY = 0
    }

    public func resetScrollToNewest(animated: Bool) {
        if animated {
            scrollTargetOffset = 0
            scrollVelocity = 0
        } else {
            scrollTargetOffset = nil
            scrollOffset = 0
            scrollVelocity = 0
            smoothedScrollVelocity = 0
            lastScrollOffsetForAccel = 0
        }
    }

    /// 1:1 direct delta for macOS trackpad / Magic Mouse (already provides native momentum deltas).
    public func applyDirectScrollDelta(_ deltaX: CGFloat) {
        scrollTargetOffset = nil
        scrollVelocity = 0
        var adjustedDelta = deltaX
        let maxOff = maxScrollOffset
        if (scrollOffset < 0 && deltaX < 0) || (scrollOffset > maxOff && deltaX > 0) {
            adjustedDelta *= 0.30
        }
        scrollOffset += adjustedDelta
    }

    /// Smooth stepped scrolling for discrete mouse wheels without velocity compounding.
    public func scrollByWheel(deltaX: CGFloat) {
        scrollVelocity = 0
        let currentTarget = scrollTargetOffset ?? scrollOffset
        let proposed = currentTarget + deltaX
        scrollTargetOffset = max(0, min(maxScrollOffset, proposed))
    }

    public func scrollBy(deltaX: CGFloat, isDirectGesture: Bool) {
        scrollTargetOffset = nil
        var adjustedDelta = deltaX
        let maxOff = maxScrollOffset
        if scrollOffset < 0 || scrollOffset > maxOff {
            // Rubber-band resistance past bounds
            adjustedDelta *= 0.35
        }
        scrollOffset += adjustedDelta
        if isDirectGesture {
            scrollVelocity = adjustedDelta * 14.0
        } else {
            scrollVelocity += adjustedDelta * 10.0
            scrollVelocity = max(-2400, min(2400, scrollVelocity))
        }
    }

    public func scrollStep(cardsDelta: Int) {
        let currentTarget = scrollTargetOffset ?? scrollOffset
        let proposed = currentTarget + CGFloat(cardsDelta) * slotSpacing
        scrollTargetOffset = max(0, min(maxScrollOffset, proposed))
        scrollVelocity = 0
    }

    public func clampScrollBounds() {
        scrollOffset = max(0, min(maxScrollOffset, scrollOffset))
        if let target = scrollTargetOffset {
            scrollTargetOffset = max(0, min(maxScrollOffset, target))
        }
    }

    // MARK: - Hover & Card Lifecycle

    public func setHovered(itemID: String?, visibleItems: [(id: String, restingAngle: CGFloat)]) {
        for (id, state) in cardStates {
            if id != itemID && state.isHovered {
                var updated = state
                updated.isHovered = false
                cardStates[id] = updated
            }
        }
        guard let itemID else { return }
        if var existing = cardStates[itemID] {
            existing.isHovered = true
            cardStates[itemID] = existing
        } else if let match = visibleItems.first(where: { $0.id == itemID }) {
            var created = CardMotionState(restingAngle: match.restingAngle)
            created.isHovered = true
            cardStates[itemID] = created
        }
    }

    public func triggerGentleBreeze(visibleItems: [(id: String, index: Int, restingAngle: CGFloat)]) {
        for entry in visibleItems {
            var state = cardStates[entry.id] ?? CardMotionState(restingAngle: entry.restingAngle)
            state.restingAngle = entry.restingAngle
            let sign: CGFloat = (entry.index % 2 == 0) ? 1.0 : -1.0
            let magnitude = 0.55 + CGFloat(entry.index % 3) * 0.16
            state.angularVelocity += sign * magnitude
            cardStates[entry.id] = state
        }
    }

    /// Runs the 4-stage choreography when a new capture finishes saving.
    public func triggerNewCapture(
        newItemID: String,
        newRestingAngle: CGFloat,
        existingItems: [(id: String, index: Int, restingAngle: CGFloat)],
        revealCurtain: Bool
    ) {
        if revealCurtain {
            if curtainOffsetY < -10 {
                curtainOffsetY = -210
            }
            setCurtain(visible: true, animated: true)
        }

        // Smoothly bring view back to newest edge if scrolled into past
        if scrollOffset > 1 {
            resetScrollToNewest(animated: true)
        }

        // Stage 1 (t=0.00s): Soft breeze makes existing cards sway gently (`rung rinh nhẹ`)
        // Stage 2 (t=0.16s): Existing cards hold old horizontal slot momentarily, then glide left
        let visibleRange = visibleIndexRange(buffer: 3)
        for existing in existingItems {
            guard visibleRange.contains(existing.index) else { continue }
            var state = cardStates[existing.id] ?? CardMotionState(restingAngle: existing.restingAngle)
            state.restingAngle = existing.restingAngle
            state.shiftOffsetX += slotSpacing
            state.shiftDelayRemaining = 0.16
            let sign: CGFloat = (existing.index % 2 == 0) ? 1.0 : -1.0
            state.angularVelocity += sign * (0.48 + CGFloat(existing.index % 3) * 0.14)
            cardStates[existing.id] = state
        }

        // Stage 3 (t=0.22s): New card launches from bottom-right up to rightmost slot
        var newState = CardMotionState(restingAngle: newRestingAngle, angle: -0.22)
        newState.pinSnapProgress = 0
        newState.pinSnapElapsed = 0
        newState.isPinSnapping = false
        newState.flyState = FlyInState(
            elapsed: -0.22,
            duration: 0.38,
            startPoint: CGPoint(x: max(120, viewportSize.width - 42), y: viewportSize.height + 90),
            targetX: rightAnchorX
        )
        cardStates[newItemID] = newState

        // Stage 1 subtle rope sway from reveal breeze
        injectRopeWave(
            at: viewportSize.width * 0.55,
            amplitude: 3.5,
            damping: 3.2,
            frequency: 11.0,
            spread: max(220, viewportSize.width * 0.45)
        )
    }

    public func triggerCardRemoval(itemID: String, screenX: CGFloat, restingAngle: CGFloat) {
        var state = cardStates[itemID] ?? CardMotionState(restingAngle: restingAngle)
        state.removeProgress = 0
        state.angularVelocity += 2.2
        cardStates[itemID] = state
        injectRopeWave(at: screenX, amplitude: -5.5, damping: 5.0, frequency: 21.0, spread: 140.0)
    }

    public func syncCardOrderForNeighbors(_ orderedIDs: [String]) -> [String] {
        orderedIDs
    }

    // MARK: - Simulation Step (Demand-Driven)

    /// Advances physics by `dt` seconds. Returns `true` if simulation is still active (more frames needed),
    /// or `false` when everything has settled completely at rest (0% CPU idle).
    @discardableResult
    public func step(dt rawDT: CFTimeInterval, orderedItemIDs: [String] = []) -> Bool {
        let dt = CGFloat(min(1.0 / 30.0, max(1.0 / 240.0, rawDT)))
        var isActive = false

        // 1. Curtain vertical spring
        let curtainDisp = curtainTargetY - curtainOffsetY
        if abs(curtainDisp) > 0.25 || abs(curtainVelocityY) > 1.0 {
            let stiffness: CGFloat = 210
            let damping: CGFloat = 24
            let accel = stiffness * curtainDisp - damping * curtainVelocityY
            curtainVelocityY += accel * dt
            curtainOffsetY += curtainVelocityY * dt
            isActive = true
        } else {
            curtainOffsetY = curtainTargetY
            curtainVelocityY = 0
        }

        // 2. Scroll physics & inertia
        let maxOff = maxScrollOffset
        if let target = scrollTargetOffset {
            let clampedTarget = max(0, min(maxOff, target))
            let diff = clampedTarget - scrollOffset
            if abs(diff) > 0.3 {
                scrollOffset += diff * min(1.0, dt * 12.0)
                scrollVelocity = diff * 6.0
                isActive = true
            } else {
                scrollOffset = clampedTarget
                scrollVelocity = 0
                scrollTargetOffset = nil
            }
        } else if !isUserScrolling {
            if abs(scrollVelocity) > 0.8 {
                scrollOffset += scrollVelocity * dt
                scrollVelocity *= exp(-7.5 * dt)
                isActive = true
            } else {
                scrollVelocity = 0
            }

            if scrollOffset < 0 {
                scrollOffset += (0 - scrollOffset) * min(1.0, dt * 15.0)
                if abs(scrollOffset) < 0.25 { scrollOffset = 0 } else { isActive = true }
                scrollVelocity *= 0.65
            } else if scrollOffset > maxOff {
                scrollOffset += (maxOff - scrollOffset) * min(1.0, dt * 15.0)
                if abs(scrollOffset - maxOff) < 0.25 { scrollOffset = maxOff } else { isActive = true }
                scrollVelocity *= 0.65
            }
        } else {
            isActive = true
        }

        // Cohesive gentle scroll sway driven by smoothed horizontal scroll velocity (prevents noisy per-card spikes)
        let instantVel = max(-1800, min(1800, (scrollOffset - lastScrollOffsetForAccel) / dt))
        lastScrollOffsetForAccel = scrollOffset
        smoothedScrollVelocity += (instantVel - smoothedScrollVelocity) * min(1.0, dt * 10.0)
        if abs(smoothedScrollVelocity) < 1.0 && abs(instantVel) < 1.0 {
            smoothedScrollVelocity = 0
        }
        let targetLean = max(-0.085, min(0.085, -smoothedScrollVelocity * 0.000075))
        let swayOmega: CGFloat = 9.0
        let swayZeta: CGFloat = 0.58
        let swayAlpha = -(swayOmega * swayOmega) * (scrollSwayAngle - targetLean) - 2.0 * swayZeta * swayOmega * scrollSwayVelocity
        scrollSwayVelocity += swayAlpha * dt
        scrollSwayAngle += scrollSwayVelocity * dt
        if abs(scrollSwayAngle - targetLean) > 0.001 || abs(scrollSwayVelocity) > 0.003 || abs(smoothedScrollVelocity) > 1.0 {
            isActive = true
        } else if targetLean == 0 {
            scrollSwayAngle = 0
            scrollSwayVelocity = 0
        }

        // 3. Rope waves
        if !waves.isEmpty {
            var remainingWaves: [RopeWave] = []
            remainingWaves.reserveCapacity(waves.count)
            for var wave in waves {
                wave.age += dt
                if wave.currentPeakAmplitude > 0.05 {
                    remainingWaves.append(wave)
                    isActive = true
                }
            }
            waves = remainingWaves
        }

        // 4. Per-card pendulums, shifts, fly-ins, pin snaps & removals
        var landedCardIDs: [String] = []
        var completedRemovals: [String] = []
        let keys = Array(cardStates.keys)

        for id in keys {
            guard var state = cardStates[id] else { continue }

            // Hover progress
            let hoverTarget: CGFloat = state.isHovered ? 1.0 : 0.0
            if abs(hoverTarget - state.hoverAmount) > 0.005 {
                state.hoverAmount += (hoverTarget - state.hoverAmount) * min(1.0, dt * 16.0)
                isActive = true
            } else {
                state.hoverAmount = hoverTarget
            }

            // Removal drop animation
            if let removeProg = state.removeProgress {
                let nextProg = min(1.0, removeProg + dt / 0.28)
                state.removeProgress = nextProg
                state.angle += state.angularVelocity * dt
                isActive = true
                if nextProg >= 1.0 {
                    completedRemovals.append(id)
                }
                cardStates[id] = state
                continue
            }

            // Stage 2: Shift left delay & spring
            var cardShiftAccel: CGFloat = 0
            if state.shiftDelayRemaining > 0 {
                state.shiftDelayRemaining = max(0, state.shiftDelayRemaining - dt)
                isActive = true
            } else if abs(state.shiftOffsetX) > 0.12 || abs(state.shiftVelocityX) > 0.5 {
                let prevVel = state.shiftVelocityX
                let stiffness: CGFloat = 155
                let damping: CGFloat = 18
                let accelX = -stiffness * state.shiftOffsetX - damping * state.shiftVelocityX
                state.shiftVelocityX += accelX * dt
                state.shiftOffsetX += state.shiftVelocityX * dt
                let shiftAccel = (state.shiftVelocityX - prevVel) / dt
                cardShiftAccel = shiftAccel * 0.55
                isActive = true
            } else {
                state.shiftOffsetX = 0
                state.shiftVelocityX = 0
            }

            // Stage 3: Fly-in arc
            if var fly = state.flyState {
                fly.elapsed += dt
                if fly.isCompleted {
                    state.flyState = nil
                    state.isPinSnapping = true
                    state.pinSnapElapsed = 0
                    state.pinSnapProgress = 0
                    state.angle = state.restingAngle + 0.09
                    state.angularVelocity = 2.35
                    landedCardIDs.append(id)
                } else {
                    state.flyState = fly
                }
                isActive = true
            }

            // Stage 4: Clothespin snap
            if state.isPinSnapping {
                state.pinSnapElapsed += dt
                let norm = min(1.0, state.pinSnapElapsed / 0.18)
                // Overshoot curve for snappy clothespin bite
                let t = norm - 1.0
                let overshoot = 1.0 + t * t * (2.6 * t + 1.6)
                state.pinSnapProgress = max(0, overshoot)
                if norm >= 1.0 {
                    state.pinSnapProgress = 1.0
                    state.isPinSnapping = false
                } else {
                    isActive = true
                }
            }

            // Damped pendulum equation
            if state.flyState == nil {
                let omega0: CGFloat = 8.2
                let zeta: CGFloat = state.isHovered ? 0.58 : 0.24
                let inertiaGain: CGFloat = 0.00028
                let alpha = -(omega0 * omega0) * (state.angle - state.restingAngle)
                    - 2.0 * zeta * omega0 * state.angularVelocity
                    + inertiaGain * cardShiftAccel
                state.angularVelocity += alpha * dt
                state.angle += state.angularVelocity * dt
                state.angle = max(-0.24, min(0.24, state.angle))

                if abs(state.angle - state.restingAngle) > 0.0015 || abs(state.angularVelocity) > 0.004 {
                    isActive = true
                } else {
                    state.angle = state.restingAngle
                    state.angularVelocity = 0
                }
            }

            // Prune totally settled, unhovered default states to keep memory minimal
            let settled = !state.isHovered
                && state.hoverAmount == 0
                && state.flyState == nil
                && !state.isPinSnapping
                && state.removeProgress == nil
                && state.shiftDelayRemaining == 0
                && state.shiftOffsetX == 0
                && state.angle == state.restingAngle
                && state.angularVelocity == 0

            if settled {
                cardStates.removeValue(forKey: id)
            } else {
                cardStates[id] = state
            }
        }

        // Trigger Stage 4 rope impact + neighbor sympathetic wave when a flying card lands!
        for landedID in landedCardIDs {
            let landingX: CGFloat
            if let idx = orderedItemIDs.firstIndex(of: landedID) {
                landingX = baseX(for: idx)
            } else {
                landingX = rightAnchorX
            }

            injectRopeWave(at: landingX, amplitude: 11.5, damping: 4.4, frequency: 19.0, spread: 190.0)
            injectRopeWave(at: landingX - slotSpacing, amplitude: 3.4, damping: 4.8, frequency: 16.0, spread: 210.0)

            // Sympathetic impulse to up to 2 left neighbors
            if let landedIdx = orderedItemIDs.firstIndex(of: landedID) {
                let neighborOffsets: [(offset: Int, kick: CGFloat)] = [(-1, 0.72), (-2, 0.30)]
                for n in neighborOffsets {
                    let neighborIdx = landedIdx + n.offset
                    guard neighborIdx >= 0, neighborIdx < orderedItemIDs.count else { continue }
                    let neighborID = orderedItemIDs[neighborIdx]
                    var neighborState = cardStates[neighborID] ?? CardMotionState()
                    neighborState.angularVelocity += n.kick
                    cardStates[neighborID] = neighborState
                }
            }
            isActive = true
        }

        for id in completedRemovals {
            cardStates.removeValue(forKey: id)
        }

        return isActive
    }

    // MARK: - Pose Query

    public func pose(for index: Int, itemID: String, restingAngle: CGFloat) -> CardRenderPose {
        let state = cardStates[itemID]
        let shiftX = state?.shiftOffsetX ?? 0
        let x = baseX(for: index) + shiftX
        let ropeAttachmentY = ropeY(atScreenX: x)
        let hoverAmt = state?.hoverAmount ?? 0

        if let fly = state?.flyState {
            if !fly.isStarted {
                return CardRenderPose(
                    anchorCenter: fly.startPoint,
                    angle: -0.22,
                    scale: 0.52,
                    opacity: 0,
                    pinSnapProgress: 0,
                    hoverAmount: 0,
                    isFlying: true,
                    removeProgress: 0
                )
            }
            let rawT = fly.progress
            // Smooth cubic ease-out
            let inv = 1.0 - rawT
            let t = 1.0 - inv * inv * inv

            let targetPoint = CGPoint(x: x, y: ropeAttachmentY)
            let controlPoint = CGPoint(
                x: max(fly.startPoint.x, targetPoint.x) + 28,
                y: min(fly.startPoint.y, targetPoint.y) + 28
            )
            // Quadratic Bezier interpolation
            let oneMinusT = 1.0 - t
            let posX = oneMinusT * oneMinusT * fly.startPoint.x
                + 2 * oneMinusT * t * controlPoint.x
                + t * t * targetPoint.x
            let posY = oneMinusT * oneMinusT * fly.startPoint.y
                + 2 * oneMinusT * t * controlPoint.y
                + t * t * targetPoint.y

            let angle = -0.22 * (1.0 - t) + 0.09 * t
            let scale = 0.52 + 0.48 * t
            let opacity = min(1.0, rawT / 0.25)
            return CardRenderPose(
                anchorCenter: CGPoint(x: posX, y: posY),
                angle: angle,
                scale: scale,
                opacity: opacity,
                pinSnapProgress: 0,
                hoverAmount: 0,
                isFlying: true,
                removeProgress: 0
            )
        }

        if let removeProg = state?.removeProgress {
            let t = removeProg
            let dropY = ropeAttachmentY + t * t * 180.0
            return CardRenderPose(
                anchorCenter: CGPoint(x: x, y: dropY),
                angle: (state?.angle ?? restingAngle) + t * 0.25,
                scale: 1.0 - 0.12 * t,
                opacity: max(0, 1.0 - t),
                pinSnapProgress: 0,
                hoverAmount: hoverAmt,
                isFlying: false,
                removeProgress: t
            )
        }

        let baseAngle = state?.angle ?? restingAngle
        let cardAngle = max(-0.24, min(0.24, baseAngle + scrollSwayAngle))
        let scale = 1.0 + hoverAmt * 0.06
        let pinSnap = state?.pinSnapProgress ?? 1.0

        return CardRenderPose(
            anchorCenter: CGPoint(x: x, y: ropeAttachmentY),
            angle: cardAngle,
            scale: scale,
            opacity: 1.0,
            pinSnapProgress: pinSnap,
            hoverAmount: hoverAmt,
            isFlying: false,
            removeProgress: 0
        )
    }
}

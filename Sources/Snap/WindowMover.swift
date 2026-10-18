import AppKit
import SwiftAppKit

/// Carries out a WindowAction on the focused window, and remembers enough to combine arrows
/// into quarters and to restore windows.
@MainActor
final class WindowMover {
    /// Two arrows this close together make a quarter (↑ then → = top right).
    private static let comboWindow: TimeInterval = 0.4
    /// Windows Snap remembers for Restore. The oldest is forgotten first.
    private static let historyLimit = 50

    private struct LastArrow {
        let direction: Layout.Direction
        let window: AXWindow
        let time: Date
    }

    /// For one window: where it was before Snap first moved it, and what Snap last did to it.
    private struct History {
        let window: AXWindow
        var restoreFrame: CGRect
        var lastFrame: CGRect
        var lastAction: WindowAction
    }

    private var lastArrow: LastArrow?
    private var history: [History] = []

    func perform(_ action: WindowAction) {
        guard Accessibility.isGranted else {
            Accessibility.request()
            return
        }
        let areas = AXWindow.displayAreas
        guard let window = AXWindow.focused(), !window.isFullScreen,
              let current = window.frame,
              let area = Layout.display(for: current, among: areas) else {
            NSSound.beep()
            return
        }
        let index = history.firstIndex { $0.window.isSame(as: window) }

        if action == .restore {
            guard let index else {
                NSSound.beep() // Snap hasn't moved this window
                return
            }
            window.setFrame(history.remove(at: index).restoreFrame)
            return
        }

        let (target, performed) = targetFrame(for: action, window: window, current: current, area: area, areas: areas, history: index.map { history[$0] })
        window.setFrame(target)
        remember(window, before: current, after: window.frame ?? target, action: performed, at: index)
    }

    /// Where `action` puts the window, and what it amounts to (an arrow can become a quarter).
    private func targetFrame(
        for action: WindowAction, window: AXWindow, current: CGRect, area: CGRect, areas: [CGRect], history: History?
    ) -> (CGRect, WindowAction) {
        switch action {
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf:
            let direction = action.direction!
            defer { lastArrow = LastArrow(direction: direction, window: window, time: Date()) }

            // A perpendicular arrow right after another one: the quarter where both halves meet.
            if let last = lastArrow, last.window.isSame(as: window),
               Date().timeIntervalSince(last.time) < Self.comboWindow,
               let quarter = Layout.quarter(last.direction, direction, of: area) {
                return (quarter, WindowAction.quarter(last.direction, direction))
            }

            // Already on that half: carry on to the next display that way, onto its near half.
            let half = Layout.half(direction, of: area)
            let alreadyThere = Layout.roughlyEqual(current, half)
                || history.map { $0.lastAction == action && Layout.roughlyEqual(current, $0.lastFrame) } ?? false
            if alreadyThere, let next = Layout.neighbor(of: area, direction, among: areas) {
                return (Layout.half(direction.opposite, of: next), direction.opposite.halfAction)
            }
            return (half, action)

        case .topLeft: return (Layout.quarter(.up, .left, of: area)!, action)
        case .topRight: return (Layout.quarter(.up, .right, of: area)!, action)
        case .bottomLeft: return (Layout.quarter(.down, .left, of: area)!, action)
        case .bottomRight: return (Layout.quarter(.down, .right, of: area)!, action)
        case .maximize: return (area, action)
        case .larger: return (Layout.resize(current, larger: true, in: area), action)
        case .smaller: return (Layout.resize(current, larger: false, in: area), action)
        case .moveUp, .moveLeft, .moveDown, .moveRight: return (Layout.move(current, action.direction!, in: area), action)
        case .restore: return (current, action) // handled in perform
        }
    }

    /// Keeps the frame from before Snap's first move, so Restore goes back there. If the window
    /// was moved by hand since Snap last touched it, that's the new place to restore to.
    private func remember(_ window: AXWindow, before: CGRect, after: CGRect, action: WindowAction, at index: Int?) {
        if let index {
            var entry = history.remove(at: index)
            if !Layout.roughlyEqual(before, entry.lastFrame) { entry.restoreFrame = before }
            entry.lastFrame = after
            entry.lastAction = action
            history.append(entry)
        } else {
            history.append(History(window: window, restoreFrame: before, lastFrame: after, lastAction: action))
            if history.count > Self.historyLimit { history.removeFirst() }
        }
    }
}

private extension WindowAction {
    /// The arrow direction of a half or a move.
    var direction: Layout.Direction? {
        switch self {
        case .leftHalf, .moveLeft: .left
        case .rightHalf, .moveRight: .right
        case .topHalf, .moveUp: .up
        case .bottomHalf, .moveDown: .down
        default: nil
        }
    }

    static func quarter(_ a: Layout.Direction, _ b: Layout.Direction) -> WindowAction {
        let vertical = a.isHorizontal ? b : a
        let horizontal = a.isHorizontal ? a : b
        switch (vertical, horizontal) {
        case (.up, .left): return .topLeft
        case (.up, _): return .topRight
        case (_, .left): return .bottomLeft
        default: return .bottomRight
        }
    }
}

private extension Layout.Direction {
    var opposite: Layout.Direction {
        switch self {
        case .left: .right
        case .right: .left
        case .up: .down
        case .down: .up
        }
    }

    var halfAction: WindowAction {
        switch self {
        case .left: .leftHalf
        case .right: .rightHalf
        case .up: .topHalf
        case .down: .bottomHalf
        }
    }
}

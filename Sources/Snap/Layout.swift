import CoreGraphics

/// Window geometry. Everything here uses Accessibility's coordinates: the origin is the top-left
/// corner of the main display and y grows downward, so "top" is `minY`. `area` is the usable part
/// of a display (no menu bar or Dock).
enum Layout {
    enum Direction {
        case left, right, up, down

        var isHorizontal: Bool { self == .left || self == .right }
    }

    /// How far one move or resize step goes, as a fraction of the display.
    static let step = 0.1

    static func half(_ direction: Direction, of area: CGRect) -> CGRect {
        switch direction {
        case .left: CGRect(x: area.minX, y: area.minY, width: area.width / 2, height: area.height)
        case .right: CGRect(x: area.midX, y: area.minY, width: area.width / 2, height: area.height)
        case .up: CGRect(x: area.minX, y: area.minY, width: area.width, height: area.height / 2)
        case .down: CGRect(x: area.minX, y: area.midY, width: area.width, height: area.height / 2)
        }
    }

    /// The quarter where two halves overlap, e.g. up + right = top right. Nil if both are on the
    /// same axis.
    static func quarter(_ a: Direction, _ b: Direction, of area: CGRect) -> CGRect? {
        guard a.isHorizontal != b.isHorizontal else { return nil }
        return half(a, of: area).intersection(half(b, of: area))
    }

    /// Grows or shrinks by one step of the display's size, keeping the center where it is, then
    /// shifts back onto the display if growing pushed it over an edge.
    static func resize(_ frame: CGRect, larger: Bool, in area: CGRect) -> CGRect {
        let sign = larger ? 1.0 : -1.0
        let minimum = CGSize(width: area.width * 0.2, height: area.height * 0.2)
        let width = min(max(frame.width + sign * area.width * step, minimum.width), area.width)
        let height = min(max(frame.height + sign * area.height * step, minimum.height), area.height)
        let resized = CGRect(x: frame.midX - width / 2, y: frame.midY - height / 2, width: width, height: height)
        return clamp(resized, to: area)
    }

    /// Slides one step in `direction`, stopping at the edge of the display.
    static func move(_ frame: CGRect, _ direction: Direction, in area: CGRect) -> CGRect {
        var moved = frame
        switch direction {
        case .left: moved.origin.x -= area.width * step
        case .right: moved.origin.x += area.width * step
        case .up: moved.origin.y -= area.height * step
        case .down: moved.origin.y += area.height * step
        }
        return clamp(moved, to: area)
    }

    /// Shifts `frame` so it's inside `area`, without resizing it. A frame bigger than the area
    /// lines up with its top-left corner.
    static func clamp(_ frame: CGRect, to area: CGRect) -> CGRect {
        var result = frame
        result.origin.x = max(area.minX, min(frame.minX, area.maxX - frame.width))
        result.origin.y = max(area.minY, min(frame.minY, area.maxY - frame.height))
        return result
    }

    /// The display that has most of `frame` on it, or the nearest one if it's on none of them.
    static func display(for frame: CGRect, among areas: [CGRect]) -> CGRect? {
        if let best = areas.max(by: { overlap($0, frame) < overlap($1, frame) }), overlap(best, frame) > 0 {
            return best
        }
        return areas.min { distance($0, frame) < distance($1, frame) }
    }

    /// The closest display past `area`'s edge in `direction`, if there is one.
    static func neighbor(of area: CGRect, _ direction: Direction, among areas: [CGRect]) -> CGRect? {
        areas
            .filter { candidate in
                switch direction {
                case .left: candidate.midX < area.minX
                case .right: candidate.midX > area.maxX
                case .up: candidate.midY < area.minY
                case .down: candidate.midY > area.maxY
                }
            }
            .min { distance($0, area) < distance($1, area) }
    }

    private static func overlap(_ a: CGRect, _ b: CGRect) -> CGFloat {
        let shared = a.intersection(b)
        return shared.isNull ? 0 : shared.width * shared.height
    }

    private static func distance(_ a: CGRect, _ b: CGRect) -> CGFloat {
        hypot(a.midX - b.midX, a.midY - b.midY)
    }

    /// Whether two frames are the same give or take a couple of points. Apps round sizes (e.g.
    /// Terminal snaps to whole characters), so exact comparisons miss.
    static func roughlyEqual(_ a: CGRect, _ b: CGRect, tolerance: CGFloat = 2) -> Bool {
        abs(a.minX - b.minX) <= tolerance && abs(a.minY - b.minY) <= tolerance
            && abs(a.width - b.width) <= tolerance && abs(a.height - b.height) <= tolerance
    }
}

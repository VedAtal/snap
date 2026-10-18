import AppKit
import ApplicationServices

/// Another app's window, moved and resized through the Accessibility API. Frames are in
/// Accessibility's coordinates (see Layout).
@MainActor
struct AXWindow {
    let element: AXUIElement
    private let app: AXUIElement

    /// The window you're working in: the focused window of the frontmost app.
    static func focused() -> AXWindow? {
        guard let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier else { return nil }
        let app = AXUIElementCreateApplication(pid)
        guard let window = copyAttribute(app, kAXFocusedWindowAttribute) else { return nil }
        // CFTypeRef → AXUIElement can't fail when the attribute is a window.
        return AXWindow(element: window as! AXUIElement, app: app)
    }

    /// The usable area of every display (no menu bar or Dock), in Accessibility's coordinates.
    static var displayAreas: [CGRect] {
        // Accessibility measures from the top-left of the main display; AppKit from its bottom-left.
        guard let mainHeight = NSScreen.screens.first?.frame.height else { return [] }
        return NSScreen.screens.map { screen in
            let area = screen.visibleFrame
            return CGRect(x: area.minX, y: mainHeight - area.maxY, width: area.width, height: area.height)
        }
    }

    var frame: CGRect? {
        guard let position = Self.copyAttribute(element, kAXPositionAttribute),
              let size = Self.copyAttribute(element, kAXSizeAttribute) else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        // Both are AXValues when present.
        guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
              AXValueGetValue(size as! AXValue, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    var isFullScreen: Bool {
        Self.copyAttribute(element, "AXFullScreen") as? Bool ?? false
    }

    /// Whether this is the same window as `other`.
    func isSame(as other: AXWindow) -> Bool { CFEqual(element, other.element) }

    func setFrame(_ frame: CGRect) {
        // With AXEnhancedUserInterface on (VoiceOver and some utilities turn it on), apps animate
        // every change and drop some of them. Turn it off while moving, then put it back.
        let enhanced = Self.copyAttribute(app, "AXEnhancedUserInterface") as? Bool ?? false
        if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanFalse) }
        defer {
            if enhanced { AXUIElementSetAttributeValue(app, "AXEnhancedUserInterface" as CFString, kCFBooleanTrue) }
        }

        // Size, position, size again: macOS won't let a window grow past the edge of the display
        // it's on, so when moving to a bigger spot (or another display), the first resize can come
        // up short. Once it's in place, the second one fits.
        setSize(frame.size)
        setPosition(frame.origin)
        setSize(frame.size)
    }

    private func setPosition(_ point: CGPoint) {
        var point = point
        if let value = AXValueCreate(.cgPoint, &point) {
            AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, value)
        }
    }

    private func setSize(_ size: CGSize) {
        var size = size
        if let value = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, value)
        }
    }

    private static func copyAttribute(_ element: AXUIElement, _ attribute: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else { return nil }
        return value
    }
}

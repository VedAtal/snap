import AppKit
import Carbon.HIToolbox
import SwiftAppKit

/// Everything Snap can do to a window. The raw value names the action's hotkey and its saved
/// shortcut, so don't rename cases.
enum WindowAction: String, CaseIterable {
    case leftHalf, rightHalf, topHalf, bottomHalf
    case topLeft, topRight, bottomLeft, bottomRight
    case maximize, restore, larger, smaller
    case moveUp, moveLeft, moveDown, moveRight

    var title: String {
        switch self {
        case .leftHalf: "Left Half"
        case .rightHalf: "Right Half"
        case .topHalf: "Top Half"
        case .bottomHalf: "Bottom Half"
        case .topLeft: "Top Left"
        case .topRight: "Top Right"
        case .bottomLeft: "Bottom Left"
        case .bottomRight: "Bottom Right"
        case .maximize: "Maximize"
        case .restore: "Restore"
        case .larger: "Larger"
        case .smaller: "Smaller"
        case .moveUp: "Move Up"
        case .moveLeft: "Move Left"
        case .moveDown: "Move Down"
        case .moveRight: "Move Right"
        }
    }

    /// ⌃⌥ because almost nothing else uses it. ⌘⌥ would take over tab switching in browsers
    /// and editors, and ⌘⌥D (show/hide the Dock) everywhere. Quarters have no default: press
    /// two arrows in a row instead.
    var defaultShortcut: Shortcut? {
        let mods: NSEvent.ModifierFlags = [.control, .option]
        return switch self {
        case .leftHalf: Shortcut(kVK_LeftArrow, mods)
        case .rightHalf: Shortcut(kVK_RightArrow, mods)
        case .topHalf: Shortcut(kVK_UpArrow, mods)
        case .bottomHalf: Shortcut(kVK_DownArrow, mods)
        case .topLeft, .topRight, .bottomLeft, .bottomRight: nil
        case .maximize: Shortcut(kVK_Return, mods)
        case .restore: Shortcut(kVK_Delete, mods)
        case .larger: Shortcut(kVK_ANSI_Equal, mods, label: "=")
        case .smaller: Shortcut(kVK_ANSI_Minus, mods, label: "-")
        case .moveUp: Shortcut(kVK_ANSI_W, mods, label: "W")
        case .moveLeft: Shortcut(kVK_ANSI_A, mods, label: "A")
        case .moveDown: Shortcut(kVK_ANSI_S, mods, label: "S")
        case .moveRight: Shortcut(kVK_ANSI_D, mods, label: "D")
        }
    }

    /// How the actions are grouped in the menu and in Settings, with a hint for Settings.
    static let groups: [(title: String, hint: String, actions: [WindowAction])] = [
        ("Halves", "Press the same arrow again to send the window to the next display that way.",
         [.leftHalf, .rightHalf, .topHalf, .bottomHalf]),
        ("Quarters", "Or press two arrows in quick succession: ⌃⌥↑ then ⌃⌥→ makes the top right quarter.",
         [.topLeft, .topRight, .bottomLeft, .bottomRight]),
        ("Size", "Restore puts a window back where it was before Snap moved it.",
         [.maximize, .restore, .larger, .smaller]),
        ("Move", "Each press moves the window a tenth of the screen.",
         [.moveUp, .moveLeft, .moveDown, .moveRight]),
    ]
}

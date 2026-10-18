import Combine
import Foundation
import SwiftAppKit

/// User settings, backed by UserDefaults. AppDelegate observes these and applies changes live.
@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()

    /// Shortcuts changed in Settings, by action. A nil value means the shortcut was cleared.
    /// Actions that aren't in here use their default.
    @Published private(set) var customShortcuts: [String: Shortcut?] {
        didSet {
            if let data = try? JSONEncoder().encode(customShortcuts) {
                defaults.set(data, forKey: Key.shortcuts)
            }
        }
    }

    private let defaults = UserDefaults.standard

    private enum Key {
        static let shortcuts = "shortcuts"
    }

    private init() {
        customShortcuts = defaults.data(forKey: Key.shortcuts)
            .flatMap { try? JSONDecoder().decode([String: Shortcut?].self, from: $0) } ?? [:]
    }

    func shortcut(for action: WindowAction) -> Shortcut? {
        Self.shortcut(for: action, in: customShortcuts)
    }

    static func shortcut(for action: WindowAction, in custom: [String: Shortcut?]) -> Shortcut? {
        if let custom = custom[action.rawValue] { return custom }
        return action.defaultShortcut
    }

    func setShortcut(_ shortcut: Shortcut?, for action: WindowAction) {
        customShortcuts[action.rawValue] = .some(shortcut)
    }

    func restoreDefaultShortcuts() {
        customShortcuts = [:]
    }
}

import AppKit
import Combine
import SwiftAppKit
import SwiftUI

/// Snap's parts on top of SwiftAppKit's standard menu bar app (menu, Settings, updates,
/// launch at login).
@MainActor
final class AppDelegate: MenuBarAppDelegate {
    private let prefs = Preferences.shared
    private let mover = WindowMover()
    private var subscriptions = Set<AnyCancellable>()

    // Moving other apps' windows always needs Accessibility.
    override var needsAccessibility: Bool { true }

    override func start() {
        registerShortcuts(prefs.customShortcuts)
        // @Published fires before the property changes, so use the value passed in.
        prefs.$customShortcuts.dropFirst()
            .sink { [weak self] custom in self?.registerShortcuts(custom) }
            .store(in: &subscriptions)
    }

    override func addMenuItems(to menu: NSMenu) {
        for (index, group) in WindowAction.groups.enumerated() {
            if index > 0 { menu.addItem(.separator()) }
            for action in group.actions {
                menu.addItem(action.title, shortcut: prefs.shortcut(for: action)) { [weak self] in
                    self?.mover.perform(action)
                }
            }
        }
        menu.addItem(.separator())
        menu.addItem("Pause Snap") { [weak self] in self?.setPaused(!HotKeyCenter.shared.isPaused) }
            .state = HotKeyCenter.shared.isPaused ? .on : .off
    }

    override func makeSettingsView() -> AnyView {
        AnyView(SettingsView(prefs: prefs))
    }

    private func registerShortcuts(_ custom: [String: Shortcut?]) {
        for action in WindowAction.allCases {
            HotKeyCenter.shared.register(action.rawValue, Preferences.shortcut(for: action, in: custom)) { [weak self] in
                self?.mover.perform(action)
            }
        }
    }

    /// Paused: the shortcuts go back to the other apps, and the menu bar icon dims.
    private func setPaused(_ paused: Bool) {
        HotKeyCenter.shared.isPaused = paused
        statusItem.button?.appearsDisabled = paused
    }
}

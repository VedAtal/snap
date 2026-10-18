import SwiftAppKit
import SwiftUI

// Note: no @State/@StateObject in here. In this SDK @State is a macro whose plugin only ships
// with full Xcode, and Snap is meant to build with just the Command Line Tools.

/// Snap's sections of the Settings window. SettingsForm adds the standard General section.
struct SettingsView: View {
    @ObservedObject var prefs: Preferences

    var body: some View {
        SettingsForm(needsAccessibility: true, height: 680) {
            ForEach(WindowAction.groups, id: \.title) { group in
                Section {
                    ForEach(group.actions, id: \.self) { action in
                        ShortcutField(action.title, shortcut: binding(for: action), hotKey: action.rawValue)
                    }
                } header: {
                    Text(group.title)
                } footer: {
                    Text(group.hint).foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Restore Default Shortcuts") { prefs.restoreDefaultShortcuts() }
            } footer: {
                Text("Click a shortcut and type a new one. Esc cancels, ⌫ removes it.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func binding(for action: WindowAction) -> Binding<Shortcut?> {
        Binding(get: { prefs.shortcut(for: action) }, set: { prefs.setShortcut($0, for: action) })
    }
}

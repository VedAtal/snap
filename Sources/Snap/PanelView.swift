import SwiftAppKit
import SwiftUI

/// What the menu bar icon opens: every action as a tile, with its shortcut. SwiftAppKit adds the footer.
struct PanelView: View {
    @ObservedObject var prefs: Preferences
    @ObservedObject var hotKeys: HotKeyCenter
    let setPaused: @MainActor (Bool) -> Void
    let perform: @MainActor (WindowAction) -> Void

    var body: some View {
        PanelToggle("Pause Snap", isOn: Binding(get: { hotKeys.isPaused }, set: setPaused))
        ForEach(WindowAction.groups, id: \.title) { group in
            PanelSection(group.title) {
                HStack(spacing: 6) {
                    ForEach(group.actions, id: \.self) { tile($0) }
                }
            }
        }
    }

    private func tile(_ action: WindowAction) -> some View {
        Button { perform(action) } label: {
            VStack(spacing: 3) {
                Image(systemName: action.symbol).font(.system(size: 16)).frame(height: 20)
                Text(action.shortTitle).font(.caption.weight(.medium)).lineLimit(1).minimumScaleFactor(0.8)
                Text(prefs.shortcut(for: action)?.displayString ?? "–")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
        }
        .buttonStyle(.panelTile)
        .help(action.title)
    }
}

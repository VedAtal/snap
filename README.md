# Snap

A small, Rectangle-style window manager for macOS. Press **⌃⌥** and an arrow to snap the window
you're working in to half the screen, two arrows in a row for a quarter, and a few more keys to
maximize, restore, resize, or nudge it.

It runs in the menu bar and uses almost no memory.

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/VedAtal/swift-app-kit/main/scripts/install.sh | bash -s snap
```

That one command does everything:

1. Checks that Swift is installed. If it isn't, it opens Apple's Command Line Tools installer;
   re-run the command once that finishes. Full Xcode isn't needed.
2. Downloads the latest version from GitHub ([VedAtal/snap](https://github.com/VedAtal/snap)),
   along with [swift-app-kit](https://github.com/VedAtal/swift-app-kit), the parts it shares with
   my other menu bar apps.
3. Creates a local code-signing certificate (first run only, see
   [why](https://github.com/VedAtal/swift-app-kit#how-setupsh-fits-together)).
4. Builds Snap and installs it to `~/Applications/Snap.app`, then deletes the download.
5. Launches it and sets it to start at login.

To work on Snap, clone the repo (`git clone https://github.com/VedAtal/snap.git`). Its
`setup.sh` takes:

| Command | Installs |
|---|---|
| `./setup.sh` | The latest commit on GitHub (the default) |
| `./setup.sh --local` | This folder as it is, including changes you haven't committed or pushed |
| `./setup.sh --build-only` | Nothing. It just builds `build/Snap.app` from this folder |
| `./setup.sh --uninstall` | Nothing. It removes Snap completely ([details](#uninstall)) |

**One manual step:** the first time Snap runs, macOS asks you to allow it under
**System Settings → Privacy & Security → Accessibility**. Turn it on. Snap can't move other
apps' windows without it.

### Updating

**To the latest on GitHub:** click **Update Snap** in the menu bar menu, or run `./setup.sh` in a clone.
Both download anything newer, rebuild, and restart Snap. If you're already on the latest
commit, they say so and change nothing. Your shortcuts and the Accessibility permission stay.

**To try local changes before pushing them:** run `./setup.sh --local`. The next
**Update Snap** or plain `./setup.sh` replaces that build with whatever is on GitHub.

The menu shows which version is running, for example **Version 59ba24f · built 2 minutes ago**.
If an update fails, nothing is replaced, and the full output is in
`~/Library/Logs/Snap/update.log`.

## Using it

| Press | To |
|---|---|
| **⌃⌥←** / **⌃⌥→** | Left half / right half |
| **⌃⌥↑** / **⌃⌥↓** | Top half / bottom half |
| Two arrows in quick succession, e.g. **⌃⌥↑** then **⌃⌥→** | That quarter (top right) |
| The same arrow again, e.g. **⌃⌥→** on a right-half window | Move it to the next display that way |
| **⌃⌥↩** | Maximize (fill the screen, minus the menu bar and Dock) |
| **⌃⌥⌫** | Restore: put the window back where it was before Snap moved it |
| **⌃⌥=** / **⌃⌥-** | Larger / smaller, by a tenth of the screen, staying centered |
| **⌃⌥W** / **A** / **S** / **D** | Move up / left / down / right by a tenth of the screen |

Snap acts on the focused window of the app in front. "Quick succession" means within 0.4
seconds, so you can keep holding ⌃⌥ and tap the two arrows.

While Snap is running, its **grid icon** sits in the menu bar at the top right. Click it to see
every action with its shortcut (click one to apply it to the window you were just in), plus
**Pause Snap**, **Launch at Login**, **Settings…**, **Update Snap**, and **Quit Snap**.

**Pause Snap** turns all the shortcuts off and gives them back to other apps until you
unpause. The menu bar icon dims while paused.

### Settings

- **Shortcuts.** Click any shortcut and type a new one. It must include ⌘, ⌃ or ⌥. Esc cancels,
  ⌫ removes it. The quarters have no shortcut by default; give them one here if you like.
  **Restore Default Shortcuts** puts everything back.
- **Launch at login**, and whether Accessibility access is granted.

## Why ⌃⌥ and not ⌘⌥

A global shortcut takes its key combination away from every other app. ⌘⌥ is already busy:
⌘⌥←/→ switches tabs in Chrome, Firefox, and VS Code, ⌘⌥D shows or hides the Dock everywhere,
and ⌘⌥W closes windows in Finder and tabs in Safari. Almost nothing uses ⌃⌥ (VoiceOver does,
but only while it's on). Rectangle uses ⌃⌥ by default for the same reason.

## Uninstall

```sh
~/Applications/Snap.app/Contents/Resources/setup.sh --uninstall
```

This removes the app, its settings, the login item, the Accessibility entry, and the signing
certificate.

## Troubleshooting

**Nothing happens when I press a shortcut.** Snap probably doesn't have Accessibility access.
The menu bar menu shows **Grant Accessibility Access…** while it's missing. If System Settings
already shows Snap as on, select it, remove it with **−**, then quit Snap from its menu and
open it again (Spotlight → Snap); macOS will ask again.

**One shortcut doesn't work.** Another app has that combination. Settings shows "Already in
use" under it. Pick a different one there.

**The Mac beeps.** Snap couldn't find a window to move: the app in front has no window, or the
window is in full screen. Restore also beeps for windows Snap hasn't moved.

**A window doesn't fill its half exactly.** Some apps only resize in steps (Terminal sizes to
whole characters) or have a minimum size. Snap gets as close as the app allows.

## How it works

Snap is built on [swift-app-kit](https://github.com/VedAtal/swift-app-kit), which provides the
parts my menu bar apps share: the install script, the global shortcuts, the menu bar menu's
standard items, the Settings window layout, launch at login, and updates. This repo holds only
what's specific to Snap:

```
Sources/Snap/
├── main.swift            Starts the app through swift-app-kit
├── AppDelegate.swift     Registers the shortcuts, adds Snap's menu items, Pause
├── WindowAction.swift    Every action: its name, default shortcut, and group
├── WindowMover.swift     Carries out an action: arrow combos, next display, Restore history
├── Layout.swift          The geometry: halves, quarters, resizing, moving, which display
├── AXWindow.swift        Reads and sets another app's window frame (needs Accessibility)
├── SettingsView.swift    Snap's sections of the Settings window
└── Preferences.swift     Changed shortcuts, saved in UserDefaults
app.env                   Name, bundle ID, icons: what swift-app-kit's setup builds
setup.sh                  Fetches swift-app-kit and runs its install script
```

A few details that aren't obvious:

- **Shortcuts don't need any permission.** They use Carbon's `RegisterEventHotKey`, which only
  sees the exact combinations Snap registered. Accessibility is needed only to move windows.
- **Two coordinate systems.** AppKit measures screens from the bottom-left corner;
  Accessibility measures windows from the top-left. Snap converts each display's usable area
  (`NSScreen.visibleFrame`) once and does all its math in Accessibility's coordinates.
- **Size, position, size.** macOS won't let a window grow past the edge of the display it's
  currently on. So Snap resizes, moves, and resizes again, which also makes moving to a bigger
  display work.
- **Combos are per window.** A second arrow only makes a quarter if it's for the same window,
  within 0.4 seconds, and on the other axis (↑ then → yes, ← then → no).
- **Restore remembers the first move.** Snap keeps a window's frame from before it first moved
  it, so you can try a few layouts and still get back. If you move the window by hand in
  between, that becomes the new place to restore to.

### Development

```sh
./setup.sh --local        # build and install what is in this folder right now
./setup.sh --build-only   # build and sign build/Snap.app without installing
swift build               # just compile
```

To change the shared parts (menu, Settings layout, shortcuts, install script), edit
[swift-app-kit](https://github.com/VedAtal/swift-app-kit) and build Snap against your local
copy with `swift package edit swift-app-kit --path ../swift-app-kit`. The kit's README explains
the rest of the workflow.

The project builds with only the Command Line Tools, so the code avoids SwiftUI's `@State` and
`@StateObject`, whose macro plugin only comes with full Xcode.

## License

MIT. See [LICENSE](LICENSE).

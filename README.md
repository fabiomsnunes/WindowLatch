# WindowLatch

> Native macOS window manager with cycling zones — the FancyZones experience for Mac, done right.

<!-- ![hero](docs/assets/hero.png) -->

WindowLatch is a personal-use, open-source window manager for macOS, built because [Rectangle Pro](https://rectangleapp.com)'s cycling behaviour wasn't quite right and Microsoft PowerToys' FancyZones isn't available on Mac.

## Features

- ⌃⌥ + arrows cycle the focused window through `2/3 → 1/2 → 1/3` zones in any direction.
- **Cross-monitor jump**: at cycle exhaustion, the window leaps to the adjacent display.
- **Jump-back**: pressing the opposite arrow within 1.5s returns to the original monitor.
- **Reverse cycle**: pressing the opposite arrow steps back through the previous direction's sequence.
- **Directional combos**: `⌃⌥+←` then `⌃⌥+↑` within 1.5s = top-left quadrant (intersection).
- **Per-monitor zone configuration**: enable/disable horizontal halves, horizontal thirds, vertical halves, vertical thirds, and quarters independently per display.
- Configurable gap, reset delay, and modifier (Ctrl+Option, Ctrl+Cmd, Cmd+Option, Ctrl+Cmd+Shift).
- Menu-bar app — no Dock clutter.

## Default shortcuts

| Action       | Shortcut |
| ------------ | -------- |
| Cycle Left   | ⌃⌥ ←     |
| Cycle Right  | ⌃⌥ →     |
| Cycle Up     | ⌃⌥ ↑     |
| Cycle Down   | ⌃⌥ ↓     |

The modifier is reconfigurable in Settings; the arrow keys are fixed.

## Install

### From GitHub Releases

1. Download the latest `WindowLatch-vX.Y.Z.dmg` from [Releases](https://github.com/fabiomsnunes/WindowLatch/releases).
2. Open the .dmg and drag **WindowLatch** to `/Applications`.
3. First launch: right-click the app → **Open** (the build is ad-hoc signed, so Gatekeeper will warn the first time).
4. Grant **Accessibility** when prompted (see below).

### Build from source

```bash
git clone https://github.com/fabiomsnunes/WindowLatch.git
cd WindowLatch
open WindowLatch.xcodeproj
# ⌘R in Xcode
```

Requires Xcode 16 or later, macOS 26 (Tahoe) target.

## Accessibility permission

WindowLatch needs **Accessibility** to move and resize windows of other apps.
On first launch the onboarding screen explains this and links to the right pane:

**System Settings → Privacy & Security → Accessibility → toggle WindowLatch on.**

The app polls the TCC database and detects the change automatically — no restart needed.

## Architecture

- **Swift 6** + **SwiftUI** (Settings) + **AppKit** (menu bar, windows)
- **Accessibility API** for window manipulation
- [**KeyboardShortcuts**](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus for global hotkeys
- Pure `CycleEngine` state machine — fully unit-tested, no AX or `Date.now` dependency
- `ScreenAdjacency` is a pure helper — also unit-tested
- Hybrid persistence: UserDefaults (gap, delay, modifier) + JSON (per-monitor zone groups)

## Limitations

- **Electron / non-native apps** (VS Code, Slack, Discord) sometimes resist `setSize` and snap back. Native apps and most well-behaved Cocoa apps work perfectly.
- **Fullscreen Spaces**: WindowLatch can't move a window that's currently in a dedicated fullscreen Space. Exit fullscreen first.
- **Screen Recording-style apps** that take over the display may steal global shortcuts.

## Contributing

PRs welcome. Before committing, run:

```bash
swiftformat .
xcodebuild test -scheme WindowLatch -destination 'platform=macOS' -only-testing:WindowLatchTests
```

CI runs SwiftFormat lint on every PR; the release workflow runs the test suite when you push a `v*` tag.

## License

[MIT](LICENSE) — © 2026 Fábio Nunes.

## Acknowledgements

Inspired by Microsoft PowerToys FancyZones. Built on top of Sindre Sorhus's KeyboardShortcuts.

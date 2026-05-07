# WindowLatch

> Native macOS window manager with cycling zones. The FancyZones experience for Mac, done right.

**Status**: 🚧 Pre-MVP1 — under active development.

WindowLatch is a personal-use, open-source window manager for macOS, built because [Rectangle Pro](https://rectangleapp.com)'s cycling behaviour wasn't quite right and Microsoft PowerToys' FancyZones isn't available on Mac.

## Planned features (MVP1)

- ⌃⌥ + arrows cycle the focused window through `2/3 → 1/2 → 1/3` zones in any direction.
- Cross-monitor jump: at cycle exhaustion, the window leaps to the adjacent display.
- Directional combos: `⌃⌥+←` then `⌃⌥+↑` within 1.5s = top-left quadrant (intersection).
- Per-monitor zone configuration (Halves / Thirds / Quadrants — multi-select).
- Configurable gap, reset delay, and shortcuts.
- Menu-bar app — no Dock clutter.

## Default shortcuts

| Action       | Shortcut |
| ------------ | -------- |
| Cycle Left   | ⌃⌥ ←   |
| Cycle Right  | ⌃⌥ →   |
| Cycle Up     | ⌃⌥ ↑   |
| Cycle Down   | ⌃⌥ ↓   |

All reconfigurable in Settings.

## Stack

- **Swift 6** + **SwiftUI** (Settings) + **AppKit** (menu bar, windows)
- **Accessibility API** for window manipulation
- [**KeyboardShortcuts**](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus for global hotkeys
- Pure `CycleEngine` state machine — fully unit-tested
- Hybrid persistence: UserDefaults (flags) + JSON (zones)

## Design docs

- [Initial plan](docs/2026-05-07-initial-plan.md) — vision and stack rationale.
- [PRDs](docs/prds/) — one per implementation step (PRD-2 through PRD-6).

## Install

> Pre-release. Install instructions land with `v0.1.0`.

## Accessibility permission

WindowLatch needs **Accessibility** to move and resize windows of other apps. Grant it in:
**System Settings → Privacy & Security → Accessibility → toggle WindowLatch on.**

## Contributing

PRs welcome once MVP1 ships. Run `swiftformat .` before committing.

## License

[MIT](LICENSE) — © 2026 Fábio Nunes.

## Acknowledgements

Inspired by Microsoft PowerToys FancyZones.

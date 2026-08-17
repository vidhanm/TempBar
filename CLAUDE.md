# TempBar — project context

Tiny macOS menu bar app showing SoC temperature with a live 5‑minute chart. Public repo: https://github.com/vidhanm/TempBar

## Layout
- `Sensors.swift` — reads temperature sensors via private `IOHIDEventSystemClient` API; `Summary.current()` gives SoC max/avg, battery, SSD.
- `main.swift` — AppKit `NSStatusItem` + custom‑drawn `Panel` NSView (header, chart with axes, footer). Timer every 3 s on `.common` run‑loop mode so it updates while the menu is open.
- `build.sh` — compiles with `swiftc`, builds `TempBar.app` (ad‑hoc signed, icon embedded).
- `assets/` — `icon.png`, `TempBar.icns`, `make_icon.swift` (renders the icon), `screenshot.png` (used in README).

## Workflow
- Build + install + relaunch:
  `./build.sh && pkill -x TempBar; rm -rf /Applications/TempBar.app && cp -R TempBar.app /Applications/ && open /Applications/TempBar.app`
- App lives in `/Applications`. "Launch at Login" is a custom-drawn `Toggle` view (NSSwitch does not paint its accent tint inside menus on macOS 26; SMAppService.status is unreliable for ad-hoc signed apps). Login item state is read/written via System Events AppleScript, matching what System Settings shows.
- Sensor probing/reading needs to run outside the sandbox.

## Facts learned
- Machine: M5 MacBook Air, macOS 26. Sensors are generic `PMU tdie*` / `PMU2 tdie*` (no CPU/GPU labels on M4/M5); we show hottest die + average.
- Menu bar item is hidden by macOS when space is tight (e.g. mic indicator) — user can ⌘‑drag it further right.
- Design decisions: keep it dependency‑free and minimal; menu bar shows one number (`36°`), colored orange ≥75 / red ≥90.
- Do not put personal paths, emails, or the `--dangerously-skip-permissions` terminal in committed files/screenshots.

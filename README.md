# Egg Timer

A tiny native macOS kitchen timer (SwiftUI), modeled on the classic M / S / ST-SP digital timer.

- **M** / **S** — add a minute / second (hold to repeat; keys `M`, `S`)
- **Start / Stop** — counts down from the set time, or up from 00:00 (`Space`)
- **Clear** — reset to 00:00 (`Esc`)
- At zero it beeps until any button is pressed, then recalls the last set time.
- Window ▸ Float on Top (⌥⌘T)

## Build

```bash
xcodegen generate
xcodebuild -scheme EggTimer -derivedDataPath build build
open build/Build/Products/Debug/EggTimer.app
```

Run tests with `xcodebuild -scheme EggTimer -derivedDataPath build test`.

## Icon

The app icon is drawn in code. To regenerate the asset set after editing it:

```bash
swift Tools/make-icon.swift
```

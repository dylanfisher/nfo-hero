# 0001. Build as a Swift package with SwiftUI, not an Xcode project

- **Date:** 2026-10-16
- **Status:** accepted

## Context

NFO Hero is a small native macOS viewer for power users. Most edits are made by coding agents,
which work reliably on plain-text files and poorly on `project.pbxproj`. The development machine
had only the Command Line Tools, no Xcode. The app must still be a real `.app` bundle so it can
declare the `.nfo` and `.diz` file types and open from Finder.

## Decision

A Swift package (Swift 6.4, Swift 6 language mode, macOS 15+) with two targets: `NFOKit` for pure,
tested logic and `NFOHero` for the SwiftUI app. `scripts/bundle` wraps the built executable and
`Resources/Info.plist` into `dist/NFO Hero.app`, ad-hoc signed. Tests use Swift Testing; format
and lint use the toolchain's `swift format`.

## Alternatives considered

- **Xcode project** — rejected: `project.pbxproj` merges badly and agents edit it unreliably, and it
  needs Xcode installed to build at all.
- **XcodeGen (`project.yml`)** — rejected for now: plain text, but adds a tool and still needs Xcode.
  Revisit if signing, entitlements or asset catalogs outgrow `scripts/bundle`.
- **One target** — rejected: tests for code inside an executable target need a host app, which is
  slower and more fragile than testing a library.
- **Three targets (kit / views / app)** — rejected: more structure than a simple viewer needs. The
  views/app split is not worth a module boundary.
- **SwiftFormat + SwiftLint** — rejected: two Homebrew tools to install and pin, for rules a small
  app doesn't need. `swift format` ships with the toolchain and can't drift from it.
- **Minimum macOS 26** — rejected: nothing used is new in 26, and 15 covers the previous release.

## Consequences

Builds, tests and the gate run with only the Command Line Tools. SwiftPM 6.4 on CLT doesn't pass
Swift Testing's macro plugin path, so `scripts/test` adds it when the folder exists; check whether
that is still needed after installing Xcode.

The macOS 27 SDK makes `@State` and `@Entry` macros from `SwiftUIMacros`, and the CLT ship no
plugin for that module, so no `-plugin-path` flag can make them build. Views hold
`State(initialValue:)` as a plain property instead, which SwiftUI finds by reflection like the
expanded `@State`, and focused values use a hand-written `FocusedValueKey`. Switch to the macros
once the toolchain has the plugin.

Code signing for distribution, notarization and app icons will need work in `scripts/bundle` when
the app ships.

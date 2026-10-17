# AGENTS.md

Instructions for AI coding agents working in this repo. Humans: see [README.md](README.md).

**Keep this file under ~50 lines.** Anything longer lives in `docs/` and is linked from here.

## Stack

- **Language:** Swift 6.4 (`.swift-version`), Swift 6 language mode, macOS 15+ (`Package.swift`)
- **Package manager:** Swift Package Manager — no Xcode project
- **Framework:** SwiftUI `DocumentGroup(viewing:)`, AppKit `NSTextView` for the text
- **Test framework:** Swift Testing (`import Testing`)
- **Layout:** `Sources/NFOKit` (pure logic), `Sources/NFOHero` (the app), `Tests/NFOKitTests` — tiers and search recipes: [docs/map.md](docs/map.md)

## Commands

| Task | Command |
|---|---|
| Install / bootstrap | `./scripts/setup` |
| Run locally | `./scripts/dev [file.nfo]` |
| Build `dist/NFO Hero.app` | `./scripts/bundle [release]` |
| Run tests | `./scripts/test` |
| **Full gate** | `./scripts/check` |

`./scripts/check` is the gate — see Definition of done.

## Principles

Non-negotiable, regardless of stack. Rationale: [docs/principles.md](docs/principles.md).

1. **Single source of truth.** Every fact — a constant, type, config value, copy string — is defined once and imported. Never re-declare, never re-derive. **Search before you create** — [docs/map.md](docs/map.md) has the recipes.
2. **Match the surrounding code.** Consistency beats personal preference. Read a neighboring file before writing a new one; map.md says which one is the neighbor.
3. **DRY on the third occurrence, not the second.** Premature abstraction costs more than duplication.
4. **Smallest change that solves the problem.** No drive-by refactors, renames, or reformatting outside the task.
5. **Fail loudly.** No empty catches, no silent fallbacks, no defaults that mask a missing value.
6. **Delete, don't comment out.** Git remembers.
7. **No new dependencies without asking first.** Say what it's for and what it replaces.
8. **Style is the formatter's job.** If a tool enforces it, it does not belong in this file or in review.

## Boundaries

- `.build/`, `dist/` and `Package.resolved` are generated. Never hand-edit them; change the last via `swift package resolve` / `update`.
- `Resources/Info.plist` is the only place for the bundle ID, name, version and file types. Read them from the bundle at runtime; never repeat them in code.
- The app never writes to, renames or moves a user's file. It is a viewer.
- The app makes no network calls.
- **Pre-release:** breaking changes are fine. Stored data has one shape — no version fields, migrations, or compatibility shims; data that doesn't match is discarded. Delete this line at the first production release.
- Never write, print, or `op read` a plaintext secret. There are none yet; [.env.example](.env.example) says how to add one.

## Definition of done

- `./scripts/check` passes clean.
- New behavior has a test that fails without the change.
- No new dependencies, no new files outside the agreed layout, no TODOs left behind.
- If a decision was non-obvious, record it in `docs/decisions/`.
- Comments, docs, and commit messages follow [docs/writing.md](docs/writing.md).

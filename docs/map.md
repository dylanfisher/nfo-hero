# Code map

Where things live, and how to find one before you build a second. Read this before creating any
new file.

This file describes **shape, not contents** — conventions and search commands, never an inventory.
An inventory would be a second copy of facts the code already holds, it would rot within a week,
and it would have no error message when it diverged. If you catch yourself listing what exists
here, stop: the grep is the list.

## Find before you create

The single rule that matters. AGENTS.md principles 1–3 (single source of truth, match the
surrounding code, DRY on the third occurrence) all depend on it — none of them can be followed
against a codebase you haven't searched.

| Before adding… | Run |
|---|---|
| any named thing | `rg -i '<name>' --type swift` |
| a type | `rg '(struct\|class\|enum\|protocol\|actor) <Name>' --type swift` |
| a helper | `rg 'func <name>' --type swift Sources/` |
| a parsing, decoding or detection rule | `ls Sources/NFOKit/` |
| a view | `rg 'View(Representable)?\b' --type swift Sources/NFOHero/` |
| a bundle value (ID, version, file types) | `plutil -p Resources/Info.plist` — the only place they live |

If a search turns up something close but not identical, that's the second occurrence. Use it or
duplicate it — do not abstract yet (principle 3).

## Tiers

Two SwiftPM targets. The dependency direction is one-way: **app → kit**.

| Tier | Path | What belongs here | May import from |
|---|---|---|---|
| **kit** | `Sources/NFOKit` | Turning an NFO's bytes into something to show: XML-vs-scene detection, Kodi XML parsing, CP437/UTF-8 decoding, artwork lookup. Pure and tested. | `Foundation` only |
| **app** | `Sources/NFOHero` | `@main`, the `DocumentGroup`, views, the `NSTextView` wrapper, menu commands. | kit, Apple frameworks |

SwiftPM's target graph stops kit importing app. `scripts/arch`, run by `./scripts/check`, fails
if kit imports anything but `Foundation` — that is what keeps it testable without the UI. Logic
that can be tested without a window goes in kit, even when only one view uses it.

Tests mirror the kit tree in `Tests/NFOKitTests/`; real NFO files for them go in its `Fixtures/`.
The app tier has no test target.

## Naming

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- One type per file; the filename is the type's name. Extensions go in `<Type>+<Topic>.swift`.
- SwiftUI and `NSViewRepresentable` views end in `View`.
- Tests are `<Type>Tests.swift`, mirroring the source path under `Tests/NFOKitTests/`.
- Acronyms keep their case: `CP437Decoder`, `NFODocument` — never `Cp437`, `Nfo`.

## Promotion

- **Third occurrence** → extract to the lowest tier that all three callers can reach (principle 3).
- **App code with no UI dependency** → move it down to kit, where it can be tested.

A promotion is its own commit, separate from whatever work revealed it (principle 4).

<!-- paths: Sources/NFOKit Sources/NFOHero -->
<!-- ↑ scripts/check verifies every path above exists. Keep it in sync with the Tiers table;
     a rename that misses this line fails the gate, which is the point. -->

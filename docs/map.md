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
| a view | `rg 'View(Representable)?\b' --type swift Sources/NFOUI/` |
| a bundle value (ID, version, file types) | `plutil -p Resources/Info.plist` — the only place they live; `scripts/bundle` copies them into the extensions' |

If a search turns up something close but not identical, that's the second occurrence. Use it or
duplicate it — do not abstract yet (principle 3).

## Tiers

Five SwiftPM targets: three executables, the app and two Quick Look extensions, that share the ui
tier. The dependency direction is one-way: **app → ui → kit** and **extension → ui → kit**.

| Tier | Path | What belongs here | May import from |
|---|---|---|---|
| **kit** | `Sources/NFOKit` | Turning an NFO's bytes into something to show: XML-vs-scene detection, Kodi XML parsing, CP437/UTF-8 decoding, BBCode conversion, artwork lookup. Pure and tested. | `Foundation` only |
| **ui** | `Sources/NFOUI` | The views that show an NFO: info cards, the `NSTextView` wrapper and its text style, artwork decoding, the Finder thumbnail's drawing. Only `NFODocumentView`, `NFOThumbnail` and what the menu needs are public. | kit, Apple frameworks |
| **app** | `Sources/NFOHero` | `@main`, the `DocumentGroup`, the document type, menu commands, the window's Show Raw and Text Encoding state. | ui, kit, Apple frameworks |
| **extension** | `Sources/NFOQuickLook`, `Sources/NFOThumbnail` | The Quick Look preview's view controller and the Finder thumbnail's provider. Sandboxed, so they cannot read the NFO's folder ([0006](decisions/0006-quick-look-preview.md), [0010](decisions/0010-finder-thumbnails.md)). | ui, kit, Apple frameworks |

SwiftPM's target graph stops kit importing ui, ui importing app or extension, and the
executables importing each other. `scripts/arch`, run
by `./scripts/check`, fails if kit imports anything but `Foundation` — that is what keeps it
testable without the UI. Logic that can be tested without a window goes in kit, even when only one
view uses it. The ui tier has no import rule: it may use any Apple framework the app may.

Tests mirror the kit tree in `Tests/NFOKitTests/`; real NFO files for them go in its `Fixtures/`.
The ui, app and extension tiers have no test target.

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

<!-- paths: Sources/NFOKit Sources/NFOUI Sources/NFOHero Sources/NFOQuickLook Sources/NFOThumbnail -->
<!-- ↑ scripts/check verifies every path above exists. Keep it in sync with the Tiers table;
     a rename that misses this line fails the gate, which is the point. -->

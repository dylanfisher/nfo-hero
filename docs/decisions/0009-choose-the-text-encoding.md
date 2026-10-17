# 0009. Let the user choose a scene NFO's text encoding per window

- **Date:** 2026-10-17
- **Status:** accepted

## Context

A scene NFO is decoded as UTF-8 when valid and CP437 otherwise
([0008](0008-dos-text-rendering.md)). Text NFOs written on Windows use Windows-1252, which is not
valid UTF-8 as soon as it has an accented letter, so it fell through to CP437: "Café" read as
"CafΘ". No byte-level rule tells 1252 from CP437 reliably, since both use every high byte.

## Decision

**View → Text Encoding** lists Automatic, which names the detected encoding, then UTF-8,
DOS (CP437) and Western (Windows-1252). The choice is per window, in `@SceneStorage` beside Show
Raw, so it is restored with the window and a new window starts at Automatic.

- `NFODocument` keeps the file's bytes, and `NFOWindowView` decodes them again with
  `NFO.parse(_:encoding:)` off the main thread when the choice changes. Choosing the encoding
  that was detected shows the document as opened, without decoding again.
- The menu is disabled for XML, which Kodi always writes as UTF-8.
- A forced UTF-8 decode replaces invalid bytes with U+FFFD. Windows-1252's five undefined bytes
  decode to the C1 controls with the same number, as Windows does.

## Alternatives considered

- **Detect Windows-1252** by its letter frequencies — rejected: a guess that is wrong for art,
  where box and block bytes dominate, and the menu is still needed when it guesses wrong.
- **One app-wide setting** — rejected: the encoding belongs to a file, and one wrong file should
  not change how the others read.
- **More encodings** (Latin-1, Shift JIS, KOI8-R) — not done. Latin-1 differs from 1252 only in
  0x80–0x9F, where Latin-1 has controls. Add others when a file needs them.

## Consequences

A window restored with a chosen encoding opens with the detected one and switches once the
decode finishes. Quick Look always uses Automatic, since it has no menu.

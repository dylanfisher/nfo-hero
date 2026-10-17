# 0008. Draw scene NFOs in Menlo, with DOS glyphs and block-height lines

- **Date:** 2026-10-17
- **Status:** accepted

## Context

Scene NFOs are drawn for a DOS text screen, where every character cell is the same size and
`█` fills its cell. The text view drew them in the system monospaced font (SF Mono), at its 16 pt
line height:

- `█` is 13 pt tall, so rows of block art had a 3 pt stripe between them.
- SF Mono has no glyph for 25 of CP437's characters, including `☺ ♥ ♪ ► ⌂` and, in the high
  range, `⌐ ∩ ≡ ⌠ ⌡`. TextKit drew those from Menlo, whose advance is 7.83 pt to SF Mono's
  8.04 pt, so the rest of their line moved left and borders stopped lining up.
- `String.Encoding`'s CP437 decodes 0x01–0x1F and 0x7F as ASCII controls, where DOS draws
  `☺` … `▼` and `⌂`.
- Art editors append a SAUCE record (128 bytes of metadata, an optional comment block and a 0x1A
  end-of-file byte), which DOS never shows and which came out as junk on the last line.

## Decision

- **Menlo, 13 pt**, which ships with macOS and has every CP437 glyph. BBCode bold uses Menlo Bold,
  with the same advance.
- **Lines are exactly as tall as `█`**: 13.25 pt in Menlo, set as the minimum and maximum line
  height of every line. TextKit takes the difference from above the ascender, so blocks touch,
  descenders keep their room, and an accent on a capital can reach into the line above, as it
  would in an 8×16 DOS cell.
- **CP437 decodes through its own table**, with DOS's glyphs for 0x01–0x1F and 0x7F, except tab,
  line feed and carriage return, which NFOs use as such. 0x00 is a space.
- **A scene NFO with any of those control bytes is CP437**, even when it is valid UTF-8, since no
  UTF-8 text contains them.
- **The SAUCE record, its comments and trailing 0x1A bytes are dropped** before decoding, for
  UTF-8 files too. A 0x1A inside the text stays.

## Alternatives considered

- **Bundle a DOS VGA font**, such as the Ultimate Oldschool PC Font Pack — rejected for now: a
  CC BY-SA dependency with attribution to carry, when Menlo covers every glyph. It would draw
  closer to DOS, with 8×16 cells and the VGA letterforms.
- **Keep SF Mono and set its line height to `█`** — rejected: the 25 missing glyphs still come
  from Menlo at the wrong width.
- **Stop at the first 0x1A**, as DOS `type` does — rejected: CP437 draws 0x1A as `→`, and a file
  could use it as one. Only trailing ones are dropped.
- **Show the SAUCE title and author** — not done; nothing asked for it yet.

## Consequences

Plain text and raw XML use the same view, so they are set tighter than before: 13.25 pt lines
instead of 16 pt. Window sizing multiplies by the same line height, so it stays exact
([0007](0007-window-size-from-content.md)). Decoding a 16 MB file with the table takes 0.05 s,
because it writes UTF-8 bytes straight into the string; appending scalars one by one took 0.4 s.

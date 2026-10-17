# 0003. Show raw text with a TextKit 1 NSTextView

- **Date:** 2026-10-16
- **Status:** accepted

## Context

Scene NFOs and raw XML show in an `NSTextView` that never wraps, because wrapped ASCII art is
unreadable. `NSTextView.scrollableTextView()` makes a TextKit 2 view, and with
`widthTracksTextView` off TextKit 2 lays out the whole document before its first draw, on the main
thread. Opening a 5 MB CP437 file blocked the app for 0.9 s; under 50 KB it costs a few
milliseconds.

## Decision

`NFOTextView` builds its text view with `NSTextView(usingTextLayoutManager: false)`. TextKit 1
draws the visible lines first and lays out the rest in idle time, which took the 5 MB open from
891 ms to 40 ms of main-thread time.

## Alternatives considered

- **Keep TextKit 2** — rejected: every bisected setting except `widthTracksTextView` is free, and
  that one is what stops lines wrapping.
- **TextKit 1 with non-contiguous layout** — rejected: it estimates the document height and finds
  the widest line only when scrolled to it, so even small files can open with the wrong scrollers.
- **Wrap lines past a size limit** — rejected: breaks the art in exactly the files it applies to.

## Consequences

While a large file is still laying out, the scrollers settle over a few seconds, and after a window
resize the text view can be wider than its longest line until layout finishes. Revisit if a later
TextKit 2 lays out unwrapped text lazily.

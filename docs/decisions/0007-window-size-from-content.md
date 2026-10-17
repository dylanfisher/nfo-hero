# 0007. Open windows at the size their content needs

- **Date:** 2026-10-17
- **Status:** accepted

## Context

Windows and Quick Look previews opened at one size, 4:5 at 90% of the visible screen height. A
ten-line `.diz` opened in a mostly empty window, and a 150-column NFO scrolled sideways. The size
has to be known before the window opens, and a scene NFO can be 16 MB, which takes seconds to lay
out.

## Decision

`WindowSize.opening(ideal:visible:)` in `NFOKit` holds the rule. Content whose ideal size, with
the title bar, fits within the visible screen's width and 90% of its height opens at that size,
but no smaller than 420 × 280 pt. Other content opens at 70% of the visible height and 4:5,
widened to the content's ideal width, up to the screen's, so wide NFOs scroll only down.

The ideal size comes from the views, through SwiftUI's unspecified proposal: the app asks for it
in `defaultWindowPlacement`, whose size is the window's frame, and the Quick Look preview reads it
as the hosting view's fitting size.

- **Text** is measured, not laid out. `TextExtent` counts lines and the longest line in columns
  while the file is parsed, off the main thread, and `NFOTextView` multiplies them by the font's
  advance and line height and adds the line padding, plus the scroller width when scrollers are
  legacy. Laid out with TextKit 1, the fixtures and a 150-column CP437 release NFO matched to the
  point: box and block characters, and bold BBCode, take the regular advance and line height.
  BBCode is measured after its tags are removed.
- **Cards** are measured by SwiftUI. A view's ideal size lays wrapping text out on one line, so
  `IdealSizeLayout` asks again at the ideal width, where the plot wraps. Files with up to ten
  items lay their cards out in a `VStack`, because a `LazyVStack` estimates the height of cards it
  has not built: 9 pt short for two or three episodes, 90 pt short for ten.

## Alternatives considered

- **Lay out the text to measure it** — rejected: TextKit lays out a 5 MB file in about a second
  on the main thread ([0003](0003-textkit-1-text-view.md)).
- **Measure the cards in an offscreen hosting view** — rejected: a second layout of the same
  views, when SwiftUI already measures the window's content for the placement.
- **Size to the content on every open, with no fallback** — rejected: a 300-line NFO would fill
  the screen's height, and the preview would cover Finder.

## Consequences

Wide characters, such as CJK and emoji, count as one column and draw wider, so a UTF-8 NFO full
of them can open with a horizontal scroller. A tab counts as four columns, at least as wide as a
tab draws with NSTextView's default 28 pt stops. The size is chosen once, when the window opens;
View → Show Raw keeps the window's size. A reopened document opens at the computed size; macOS
restores saved frames only for windows it restores at launch.

# 0005. Draw the BBCode in scene NFOs

- **Date:** 2026-10-17
- **Status:** accepted

## Context

Many release NFOs are written to be pasted into tracker and forum posts, so they carry BBCode.
A typical one wraps the whole file in `[font=Courier New]…[/font]`, marks each section heading
with `[color=#3774F6][b]…[/b][/color]`, and lists screenshots as
`[url=<full size>][img]<thumbnail>[/img][/url]`. Shown verbatim, the tags clutter the text view.
The same files are mostly ASCII art, which uses `[` and `]` as drawing characters.

## Decision

`BBCodeText` in `NFOKit` converts the BBCode of a scene NFO into text plus style runs, and the
text view draws the runs. **View → Show Raw** (⌥⌘U) switches to the source. A scene NFO with no
convertible tag stays plain text, as before, and Show Raw stays disabled for it.

- **Styled:** `[b]`, `[i]`, `[u]`, and `[color=…]` with `#RRGGBB`, `#RGB` or a CSS basic color
  name. Bold and italic stay monospaced.
- **Tags removed, content kept:** `[size]`, `[font]`, `[center]`, `[quote]`, `[code]`,
  `[spoiler]`, `[hide]` and `[pre]`. The text is always monospaced and left-aligned, because
  centering or resizing would break the art.
- **Links and images:** `[url=X]text[/url]` shows the text, `[url]X[/url]` and `[img]X[/img]` show
  X, and `[url=X][img]Y[/img][/url]` shows X once, with a space between neighbors on one line.
  Nothing is fetched and nothing is clickable: the app makes no network calls (decision 0004),
  and link detection stays off.
- **Literal fallback:** only well-formed pairs of known tags convert. Unknown tags, a closer with
  no open tag of its name, the openers a closer skips over (`[b][i]x[/b][/i]` converts only `b`),
  values with a line break or over 2048 characters, colors that do not parse, and tags past 32
  levels deep stay in the text as written.
- **Columns:** removing a tag changes only the line it is on. A line that held nothing but tags,
  like the `[font=…]` line above the art, is removed along with its line break.
- **Colors** are used as written when they reach 3:1 contrast with the text background of the
  current appearance, and otherwise mixed toward black (light backgrounds) or white (dark) just
  enough to reach it. 3:1 is WCAG 2's minimum for large text; it keeps `#3774F6` unchanged in
  both appearances while fixing `[color=black]` in Dark Mode and `[color=yellow]` on white.

## Alternatives considered

- **Strip the tags and show plain text** — rejected: the headings are the structure of the file.
- **Regex replacement** — rejected: nested quantifiers on 16 MB of brackets risk backtracking, and
  pairing needs a stack anyway. The parser is two linear passes over UTF-16 code units.
- **Colors exactly as written** — rejected: black on Dark Mode's background is invisible.
- **4.5:1 contrast** (WCAG body text) — rejected: it shifts the common tracker blue in both
  appearances, for a gain only on colors that were already readable.
- **Clickable links, or loading `[img]`** — rejected: breaks the no-network boundary, and links in
  untrusted files are a phishing surface.
- **Repair mis-nested tags** — rejected: guessing intent in a file of brackets turns ASCII art into
  formatting. Leaving them literal shows what the file says.

## Consequences

Parsing a 15 MB file of typical BBCode takes about 0.1 s, and styling it in the text view about
0.03 s, in a release build. A hostile file with 1.7 million alternating runs takes about 0.9 s
before the window draws. Copying from the rendered view copies the converted text.

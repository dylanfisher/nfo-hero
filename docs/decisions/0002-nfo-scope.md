# 0002. Support both media-server XML and scene NFOs

- **Date:** 2026-10-16
- **Status:** accepted

## Context

".nfo" names two unrelated formats. Media servers and their managers (Kodi, Radarr, Sonarr,
Lidarr, Jellyfin, Emby, tinyMediaManager) write UTF-8 XML in the Kodi schema. Release groups write
plain-text NFOs with ASCII art in DOS code page 437, sometimes UTF-8. A typical library folder
holds the media server's NFO next to its artwork:

```
poster.jpg
fanart.jpg
Jurassic Park (1993) [Remux-2160p] {tmdb=329}.mkv
Jurassic Park (1993) [Remux-2160p] {tmdb=329}.nfo
```

## Decision

Detect the kind per file. A file whose first non-whitespace character is `<` is XML; anything else
is a scene NFO, decoded as UTF-8 when valid and CP437 otherwise. `.diz` files are scene NFOs.

- **XML** with a Kodi root (`movie`, `tvshow`, `episodedetails` — possibly several per file,
  `musicvideo`, `album`, `artist`) shows as an info card: artwork, title and year, plot, ratings,
  runtime, genres, cast, and show/season/episode for episodes. **View → Show Raw** (⌥⌘U) switches
  to the XML text. Any other XML root opens in the raw view.
- **Artwork is local only:** `<name>-poster.*`, `poster.*`, `folder.*` or `cover.*` (`.jpg`,
  `.jpeg` or `.png`) beside the NFO. With none, the card has no image. `<name>-fanart.*` or
  `fanart.*` is a faded backdrop behind the cards.
- **Scene NFOs** show in the unwrapped monospaced text view.

## Alternatives considered

- **Scene NFOs only** — rejected: the main use is media-server libraries.
- **XML only** — rejected: release NFOs often sit in the same folders, and detection is one check.
- **Raw XML only** — rejected: the card is what the file is opened to see; raw stays one shortcut
  away for checking scraper output.
- **Fetch `<thumb>` URLs from TMDB** — rejected: breaks the no-network boundary, and managers already
  save artwork beside the NFO.

## Consequences

Parsing and detection live in `NFOKit` and are tested against real files in
`Tests/NFOKitTests/Fixtures/`. Plex is out of scope because it does not use NFOs.

XML that fails to parse still opens: `NFO.parse` returns it with the `malformedXML` kind, which
carries the parser's line, column and message, so the raw view can say why there is no card. A
file that starts with `<` but is not UTF-8 throws instead, because there is no text to show.
Before parsing, `<?xml ...?>` declarations are removed, anything after the last `>` (Kodi's
optional scraper URL line) is dropped, and the rest is wrapped in a synthetic root so files with
several root elements parse.

The files are untrusted downloads, so parsing is bounded. The synthetic root also rejects any
`<!DOCTYPE>`, which Kodi NFOs never have, so a file cannot declare entities. Files over 16 MB throw
`FileTooLargeError`. XML nested more than 256 deep is reported as malformed, because freeing a
deeper tree overflowed the stack. A card lists the first 100 cast members and says how many more
Show Raw has. Card text drops bidi override and isolate controls; the raw view keeps them.

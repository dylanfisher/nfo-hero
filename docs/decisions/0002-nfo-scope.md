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
- **Artwork is local only:** `<name>-poster.*`, `poster.*`, `folder.*` or `cover.*` (`.jpg`/`.png`)
  beside the NFO. With none, the card has no image. `fanart.*` is a candidate card backdrop.
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

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
is a scene NFO, decoded as UTF-8 when valid and CP437 otherwise
([0008](0008-dos-text-rendering.md)). `.diz` files are scene NFOs.

- **XML** with a Kodi root (`movie`, `tvshow`, `episodedetails` — possibly several per file,
  `musicvideo`, `album`, `artist`) shows as an info card: artwork, title and year, plot, ratings,
  runtime, genres, cast, show/season/episode for episodes, and the `<streamdetails>` that Kodi
  and the managers read from the media file: resolution, video codec and HDR type, each audio
  stream's codec, channels and language, and the subtitle languages. **View → Show Raw** (⌥⌘U) switches
  to the XML text. Any other XML root opens in the raw view.
- **Artwork is local only:** `<name>-poster.*`, `poster.*`, `folder.*` or `cover.*` (`.jpg`,
  `.jpeg` or `.png`) beside the NFO. With none, the card has no image and leaves no space for
  one. `<name>-fanart.*` or `fanart.*` is a faded backdrop behind the cards.
- **The poster's space is held while it loads.** The folder is listed before the card's first
  layout, and a found poster gets a 200 pt wide placeholder at once: 2:3 for movies, shows and
  episodes, square for albums and artists. The image fades in when decoded (no fade with Reduce
  Motion), fitted inside that frame at the top rather than cropped, so a poster of another shape
  never moves the text. A poster that does not decode keeps the frame with a neutral fill and a
  badge, since removing it would move text the user has started reading. The fanart fades in
  behind the cards and has no layout to shift.
- **Scene NFOs** show in the unwrapped monospaced text view, with any BBCode drawn as bold,
  italic, underlined and colored text, and Show Raw switching to the source
  ([0005](0005-bbcode-in-scene-nfos.md)).
- **Quick Look** shows the same views without Show Raw, and info cards there have no artwork: the
  preview extension is sandboxed and cannot list the NFO's folder
  ([0006](0006-quick-look-preview.md)). With no file to load, the card leaves no space for a
  poster.

## Alternatives considered

- **Scene NFOs only** — rejected: the main use is media-server libraries.
- **XML only** — rejected: release NFOs often sit in the same folders, and detection is one check.
- **Raw XML only** — rejected: the card is what the file is opened to see; raw stays one shortcut
  away for checking scraper output.
- **Fetch `<thumb>` URLs from TMDB** — rejected: breaks the no-network boundary, and managers already
  save artwork beside the NFO.
- **List the folder in the task that decodes the poster** — rejected: the task starts after the
  first layout, so the card was laid out without a poster area and then moved.
- **Crop every poster to fill the 2:3 frame** — rejected: square album covers would lose a third of
  their width. Fitting looks the same for the usual 2:3 poster.

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
BBCode tags nested more than 32 deep stay literal.

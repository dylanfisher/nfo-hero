# 0010. Draw Finder thumbnails with a Quick Look thumbnail extension

- **Date:** 2026-10-17
- **Status:** accepted

## Context

Finder drew NFO icons with the system's plain-text thumbnailer, which decodes them as Mac Roman:
block art came out as `€` and `Ã`, a SAUCE record showed as text, and BBCode tags as written.
Like previews, third-party thumbnails come only from a sandboxed app extension
(`com.apple.quicklook.thumbnail`), which the project builds with SwiftPM the way it builds the
preview extension ([0006](0006-quick-look-preview.md)).

## Decision

`NFOThumbnail.appex`, beside the preview extension in `Contents/PlugIns`, built and signed the same
way, with ID suffix `.Thumbnail`. Its `ThumbnailProvider` parses the file and hands the drawing to
`NFOThumbnail` in `NFOUI`.

- **It draws the art of a scene NFO**, with its BBCode styles. The font, line height and styles come from `NFOTextStyle`, which the text
  view uses too, so a thumbnail looks like the window.
- **The page** is the art's width, between 40 and 100 columns, plus a 2-column margin, and as
  tall as the text up to 1.3 times its width. Lines past the edge are cut off, not wrapped. Only
  the lines on the page are styled, so a large file costs its parse, not its styling.
- **Always dark text on a light page.** The extension cannot read the app's Dark Text Background
  setting, and Finder draws other documents' thumbnails on white.
- **XML NFOs get no thumbnail**, so Finder shows the NFO document icon: a white page with "NFO" in
  block letters, drawn by `scripts/document-icon.swift` when the app is bundled. Drawn XML was
  grey lines at icon size, the same for every movie. The card would need the folder's poster,
  which the sandbox keeps out of reach, and it is SwiftUI, which `ImageRenderer` cannot draw with
  its `NSTextView`. When the provider declines, Quick Look does not fall back to the system's
  text thumbnail.

## Alternatives considered

- **Render `NFODocumentView` to an image** — rejected: `ImageRenderer` does not draw
  `NSViewRepresentable` views, and an offscreen window per thumbnail is a lot of machinery in an
  extension that Quick Look may run many times at once.
- **Keep the system thumbnail** — rejected: it is the wrong text for every CP437 file.
- **Draw XML NFOs' source**, as the first version did — rejected: unreadable at icon size.
- **The system's generated document icon** (`UTTypeIcons` with `UTTypeIconText`) — rejected: it
  needs an asset catalog, which only Xcode's `actool` compiles.
- **Commit the `.icns`** — rejected: a binary copy of what the script draws. The script runs only
  when it is newer than the icon cached in `.build/document-icon`.

## Consequences

The text style moved out of `NFOTextView` into `NFOTextStyle`, a type with no actor, because
SwiftUI views are main-actor isolated and Quick Look draws thumbnails on other threads.

Testing needs the agent to see the new extension. After `pluginkit -a` the running
`com.apple.quicklook.ThumbnailsAgent` kept using the system's text extension until it was killed;
it restarts on demand. It also caches thumbnails per file, so copy a file to see a new rendering.
`qlmanage -t` did not use the extension; `QLThumbnailGenerator` from a small script did.

LaunchServices takes the type declaration from one registered copy of the app. A stale copy of
NFO Hero elsewhere on the disk, declaring the type without an icon, won over `dist/` until it was
removed with `lsregister -u <path>`. File icons were cached past that; the type's icon,
`NSWorkspace.icon(for:)`, showed the new one at once.

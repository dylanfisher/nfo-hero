# 0004. Ship with the hardened runtime but without App Sandbox

- **Date:** 2026-10-17
- **Status:** accepted

## Context

NFO Hero opens files downloaded from the internet, so the file and the images beside it are
untrusted input. App Sandbox with `com.apple.security.files.user-selected.read-only` would limit
what a compromised parser or image decoder could read to the files the user opened.

The card needs the NFO's folder, though. `Artwork` lists it to find `poster.*`, `folder.*`,
`cover.*`, `<name>-poster.*` and the fanart. A sandboxed build, ad-hoc signed with those two
entitlements, opened `movie.nfo` but could not list its folder (`NSCocoaErrorDomain` 257, POSIX
`EPERM`), so every card lost its artwork.

## Decision

Sign with the hardened runtime (`codesign --options runtime` in `scripts/bundle`) and no
entitlements. Do not enable App Sandbox until it can read the artwork without exceptions.

## Alternatives considered

- **Related items** (`NSIsRelatedItemType` in `CFBundleDocumentTypes`) — rejected: it grants
  access only to a file with the same name and a different extension, such as `movie.jpg` for
  `movie.nfo`. Radarr, Sonarr and Kodi name artwork `poster.jpg` or `<name>-poster.jpg`.
- **Ask for the folder with an open panel and keep a security-scoped bookmark** — rejected for
  now: a second prompt for every library folder, for a viewer whose point is opening fast.
- **`temporary-exception` file entitlements, or `assets.movies.read-only`** — rejected:
  exceptions are what the sandbox exists to avoid, and libraries rarely live only in `~/Movies`.
- **Sandbox and drop artwork** — rejected: the poster is most of the card.

## Consequences

Without the sandbox, the defenses are in the code: XML NFOs cannot declare a DOCTYPE, so no
entity expansion or external fetches; files over 16 MB, XML nested more than 256 deep and casts
past 100 rows are bounded (see `NFO`, `XMLTreeBuilder` and `MediaItem+Formatting`); artwork must
be a regular file in the NFO's folder and decode as JPEG or PNG.

No network entitlement is granted, and none is needed: the app makes no network calls. If the
app is ever sandboxed, `com.apple.security.network.client` must stay off. Revisit when shipping
through the Mac App Store, which requires the sandbox, or if macOS adds a way to grant a
document's folder.

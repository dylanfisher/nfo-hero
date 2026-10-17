# NFO Hero

A fast, minimal macOS viewer that renders NFO files' CP437 ASCII art the way it was drawn.

It opens both kinds of `.nfo`: the XML that Kodi, Radarr, Sonarr and Jellyfin write next to your
media, shown as an info card with the folder's `poster.jpg`, and release NFOs with their DOS
ASCII art intact. It never writes to your files and makes no network calls.

Requires macOS 15 or later.

## Build and run

Needs Swift 6.4 — the Xcode Command Line Tools are enough.

```sh
./scripts/setup                 # check the toolchain, resolve packages, install the commit hook
./scripts/dev                   # build dist/NFO Hero.app and open it
./scripts/dev path/to/file.nfo  # ...with a file
./scripts/bundle release        # optimized build, prints the .app path
```

## Develop

`./scripts/check` is the gate: lint, build with warnings as errors, the `NFOKit` import rule, and
tests. It runs every step and lists every failure. CI runs the same command.

| Path | Purpose |
|---|---|
| `Sources/NFOKit/` | Detection, parsing and decoding. Imports only Foundation, fully tested. |
| `Sources/NFOHero/` | The SwiftUI app. |
| `Tests/NFOKitTests/` | Swift Testing suite, with real NFO files in `Fixtures/`. |
| `Resources/Info.plist` | Bundle ID, version and file types — the only place they're defined. |
| `AGENTS.md` | Instructions for coding agents. |
| `docs/map.md` | Where things live and how to find them. |
| `docs/writing.md` | Comment voice and commit format. |
| `docs/decisions/` | Why things are the way they are. |

## License

[MIT](LICENSE)

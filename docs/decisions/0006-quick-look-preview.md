# 0006. Preview NFOs in Quick Look with a sandboxed extension

- **Date:** 2026-10-17
- **Status:** accepted

## Context

Pressing space on an NFO in Finder showed the system's plain-text preview: the XML source instead
of the card, and BBCode tags as written. Quick Look loads third-party previews only from app
extensions (`com.apple.quicklook.preview`), and requires them to run in App Sandbox. The project
builds with SwiftPM and the Command Line Tools ([0001](0001-swiftpm-swiftui-app.md)), which have no
app extension target type.

## Decision

A view-based preview extension, `NFOQuickLook.appex`, inside the app's `Contents/PlugIns`. Its
`PreviewViewController` parses the file off the main thread and shows `NFODocumentView` from
`NFOUI`, so Quick Look draws the same card, BBCode and raw text with error banner as the window.

- **Built by SwiftPM** as an executable target linked with `-e _NSExtensionMain`, Foundation's
  extension entry point, which loads the principal class named in the Info.plist. It is compiled
  with `-parse-as-library`: otherwise SwiftPM treats a one-file executable as top-level code, its
  globals are set up by a `main` that never runs, and they read as zero. A file-scope `Logger`
  logged nothing until this was added.
- **Info.plist:** `Resources/QuickLook-Info.plist` holds only the extension's own keys.
  `scripts/bundle` adds the bundle ID (the app's plus `.QuickLook`), both versions, the minimum
  macOS and `QLSupportedContentTypes` from the app's `Resources/Info.plist` and `Package.swift`.
- **Signing:** `scripts/bundle` signs the extension first, with the hardened runtime and
  `Resources/QuickLook.entitlements` (App Sandbox and nothing else), then the app. On macOS 26.6
  `pluginkit` registers the ad-hoc signed extension and Quick Look runs it sandboxed; no
  certificate is needed to use it locally.
- **No artwork.** In the sandbox, listing the NFO's folder fails with `NSCocoaErrorDomain` 257
  (POSIX `EPERM`): Quick Look grants read access to the previewed file only. The controller passes
  no file URL, so the card has no poster area and no fanart.
- **No Show Raw.** The window's Show Raw state moved from the shared views to the app's
  `NFOWindowView`, and the views take it as an optional binding. `@SceneStorage` outside an app's
  scenes logs a fault that says it "will become a fatal error in a future release". The preview
  passes nil: it shows the rendered form, and a long cast says "and N more" without pointing at a
  menu it does not have.

## Alternatives considered

- **Data-based preview** (`QLPreviewProvider` returning HTML or an attributed string) — rejected:
  a second renderer for the card and BBCode, to keep in step with the views.
- **A `.qlgenerator` plug-in** — rejected: deprecated, and current macOS no longer loads them.
- **An unsandboxed extension, or a temporary-exception entitlement for the folder** — rejected:
  Quick Look requires the sandbox, and exceptions are what it exists to prevent (see
  [0004](0004-no-app-sandbox.md)).
- **A `main.swift` that calls `NSExtensionMain`** — rejected: it would declare a private
  Foundation function by hand through `@_silgen_name`, where the linker flag uses the exported
  symbol as is.
- **A thumbnail extension** — not done yet. Finder shows the generic document icon.

## Consequences

`unsafeFlags` stop the package being used as a dependency, which an app never is. Preparing a
preview took under 10 ms for the test fixtures and a 5 KB BBCode release NFO, in a debug build.

Rebuilding `dist/` replaces the extension's bundle, and the registration from a `pluginkit -a`
straight after a rebuild was sometimes dropped; registering again worked. Launching the app also
registers it. `qlmanage -p <file>` opens a preview from the command line, and `qlmanage -r`
resets Quick Look's caches. Shipping with a Developer ID will need the extension signed with the
same identity as the app.

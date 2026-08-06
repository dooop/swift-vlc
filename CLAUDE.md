# swift-vlc

Swift Package that wraps VideoLAN's VLCKit `xcframework`s for macOS, iOS and tvOS and adds an
optional SwiftUI player UI.

- `VLC` — thin re-export of the platform-specific VLCKit module (`VLCKit` / `MobileVLCKit` /
  `TVVLCKit`), plus the linker settings each platform needs.
- `VLCPlayer` — SwiftUI `VLCPlayer(url:)` view with built-in controls. Re-exports `VLC`.

## Build with xcodebuild; `swift test` does not work

`swift build` works, but it is a smoke test only. **Anything that has to run — the test suites —
must go through `xcodebuild`**, and a change counts as verified only when xcodebuild built it for
all three platforms.

Two SwiftPM limitations are at play:

1. **String Catalog symbols.** `Sources/VLCPlayer` uses `.audio`, `.cancel`, `.disable`, … Xcode
   generates those `LocalizedStringResource` members from `UI/Resources/Localizable.xcstrings` into
   `DerivedSources/GeneratedStringSymbols_Localizable.swift`; SwiftPM does not run that generator.
   `Sources/VLCPlayer/UI/LocalizedStrings.swift` is a hand-written mirror guarded by `#if !Xcode`
   (Xcode defines the `Xcode` compilation condition), so exactly one of the two definitions is
   compiled and there is no redeclaration. **A new catalog key must be added in both places.**
2. **Test bundles do not get the framework.** `swift test` builds, then dies at load time with
   `Library not loaded: @loader_path/../Frameworks/VLCKit.framework/…` — SwiftPM does not embed
   binary framework targets into an xctest bundle. Fixing that would need `.unsafeFlags`, which
   would make this package unusable as a dependency. So: run tests with `xcodebuild`.

`swift package dump-package`, `resolve` and `compute-checksum` are all fine.

Use the helper for destinations so no simulator name is hard-coded (names differ per Xcode version
and per CI runner image):

```bash
# compile-only, all three platforms
xcodebuild build -scheme VLCPlayer -destination "$(Scripts/xcode-destination.sh macos build)"
xcodebuild build -scheme VLCPlayer -destination "$(Scripts/xcode-destination.sh ios build)"
xcodebuild build -scheme VLCPlayer -destination "$(Scripts/xcode-destination.sh tvos build)"

# build + run tests
xcodebuild test -scheme swift-vlc-Package -destination "$(Scripts/xcode-destination.sh macos)"
xcodebuild test -scheme swift-vlc-Package -destination "$(Scripts/xcode-destination.sh ios)"
xcodebuild test -scheme swift-vlc-Package -destination "$(Scripts/xcode-destination.sh tvos)"
```

Schemes: `swift-vlc-Package` (everything, incl. tests), `VLC`, `VLCPlayer`.

Pass `-derivedDataPath .derivedData` to keep build products out of the shared DerivedData folder;
`.derivedData/` is git-ignored. `xcodebuild` is verbose — grep for `error:`, `warning:`,
`BUILD SUCCEEDED`, `TEST SUCCEEDED` rather than dumping full logs.

A change is only verified when it built for **all three** platforms. Conditional compilation is
everywhere in this package, so a macOS-only build proves very little.

## Layout

| Path | Purpose |
| --- | --- |
| `Sources/VLC/VLC.swift` | `@_exported import` of the right VLCKit module per platform |
| `Sources/VLCPlayer/VLCPlayer.swift` | public `VLCPlayer` view, lifecycle, control auto-hide timer, platform input handling |
| `Sources/VLCPlayer/UI/View/` | `PlayerView` (NS/UIViewControllerRepresentable host), `PlayerControls`, `PlayerTrackButton`, tvOS `Slider` |
| `Sources/VLCPlayer/UI/ViewModel/PlayerViewModel.swift` | `@MainActor` `ObservableObject`, owns `VLCMediaPlayer`, `VLCMediaPlayerDelegate` bridge |
| `Sources/VLCPlayer/UI/Model/` | `PlayerState`, `PlayerTrack` |
| `Sources/VLCPlayer/UI/LocalizedStrings.swift` | SwiftPM-only mirror of the generated catalog symbols (`#if !Xcode`) |
| `Sources/VLCPlayer/UI/Resources/Localizable.xcstrings` | String Catalog (en, de) |
| `Tests/VLCTests/` | VLCKit linkage smoke tests |
| `Tests/VLCPlayerTests/` | model + localization tests |
| `Scripts/` | framework download/packaging and destination helpers |

## Platform rules

Deployment targets: macOS 15, iOS 18, tvOS 18. Swift tools 6.0, Swift 6 language mode (strict
concurrency is on — `PlayerViewModel` is `@MainActor` and its delegate callbacks are `nonisolated`
and hop back via `Task { @MainActor in … }`; keep that pattern).

- Prefer `#if os(tvOS)` / `#if os(macOS)` / `#if canImport(UIKit)` over runtime checks.
- macOS uses `NSViewControllerRepresentable`, iOS/tvOS use `UIViewControllerRepresentable`.
- tvOS has no SwiftUI `Slider` — `Sources/VLCPlayer/UI/View/Slider.swift` provides a focus-driven
  `UIViewRepresentable` replacement that shadows the SwiftUI type. Any change to the seek bar must be
  checked on tvOS, and focus behaviour (`@FocusState`, `canBecomeFocused`, `didUpdateFocus`) is the
  part that breaks most easily.
- tvOS reacts to `onPlayPauseCommand` / `onMoveCommand`, macOS to `onTapGesture` / `onKeyPress(.space)`.
- Keep `#Preview` blocks compiling — they are part of the build and previously broke the build
  (`fix: swift ui previews`).

## Localization

Strings live only in `Sources/VLCPlayer/UI/Resources/Localizable.xcstrings`. Never hard-code a
user-facing string, and never add a `.strings`/`.stringsdict` file.

Adding a string means: add the key to the catalog with an `en` and a `de` entry, add the matching
member to `UI/LocalizedStrings.swift`, then use the symbol (`.myNewKey`) — Xcode derives the symbol
name by lower-camel-casing the key. Only `LocalizedStringResource` extensions exist, so use APIs
that take one (`String(localized:)`, `Text(_:)`, `Button(_:role:)`), not `LocalizedStringKey`
literals. See the `add-localized-string` skill.

## VLCKit binary targets

`Package.swift` declares three `binaryTarget`s pointing at **zip archives attached to this repo's
own GitHub releases** (`binaryBaseURL`), not at videolan.org. The upstream tarballs listed in
`Scripts/vlc-frameworks.conf` are the source; they are repackaged as `.xcframework.zip` because
SwiftPM only accepts zip.

Consequences to keep in mind:

- **`ditto -c -k` is not byte-reproducible.** Re-zipping the same xcframework twice produces
  different checksums. Therefore the checksum in `Package.swift` must always be taken from the
  archive that was actually uploaded — never from a locally re-created one. This rules out any
  "rebuild and verify" scheme; see `.github/workflows/vlckit-assets.yml`.
- A release tag whose `binaryBaseURL` points at a tag that has no published assets breaks every
  consumer of that tag. Reusing a previous tag's assets is fine and intended when VLCKit itself did
  not change (0.3.1 reuses the 0.3.0 assets).
- `swift package resolve` / any `xcodebuild` run downloads ~700 MB of binary targets on a cold
  cache and validates the checksums. A checksum error there means `Package.swift` disagrees with the
  published asset.
- `Scripts/update-vlc-frameworks.sh` installs the frameworks into `Frameworks/` for local
  inspection. `Package.swift` does **not** reference `Frameworks/`; it is not part of the build.

Bumping VLCKit is the `update-vlckit` skill.

## Style

- swift-format with the repo's `.swift-format` (2 spaces, 100 columns). Before finishing, run
  `xcrun swift-format format --in-place --recursive Sources Tests Package.swift`.
- Every Swift file starts with the `//  <Name>.swift` / `//  swift-vlc` / `//  Created by …` header
  comment. Match it in new files.
- Types stay `internal` unless they are part of the public surface. Today the public API is exactly
  `VLCPlayer(url:)` plus whatever `VLC` re-exports — do not widen it casually.
- Tests use Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest.
- Tests must not start playback or hit the network; CI runners are headless.
- Commits follow Conventional Commits (`feat:`, `fix:`, `docs:`, optional scope like `fix(tvos):`).

## CI

`.github/workflows/ci.yml` runs format check, manifest check and a build+test matrix over the three
platforms on every push and PR. `release.yml` runs on a `X.Y.Z` tag. `vlckit-assets.yml` is the
manual VLCKit bump. See the `release` and `update-vlckit` skills before touching a release.

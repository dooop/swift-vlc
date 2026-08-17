# VLC Player

This is a multi-platform repository with a SwiftUI/VLCKit package for Apple platforms and a
Jetpack Compose/LibVLC library for Android. Do not describe or treat it as Swift-only.

Read `swift/README.md` before Apple-platform work and `android/README.md` before Android work.

## Layout

| Path | Purpose |
| --- | --- |
| `Package.swift` | Swift package manifest; this is the only Swift package file intentionally kept at root |
| `swift/Sources/` | Swift package source targets |
| `swift/Tests/` | Swift Testing targets |
| `swift/Scripts/` | VLCKit packaging and Xcode destination helpers |
| `swift/.swift-format` | Swift formatting rules |
| `android/vlc-player/` | Compose/LibVLC Android library |
| `android/app/` | Runnable Android sample |
| `build.gradle.kts`, `settings.gradle.kts`, `gradle/`, `gradlew*` | Root Android build |

When adding a Swift target, give it an explicit `swift/Sources/...` or `swift/Tests/...` path in
`Package.swift`. Keep new Swift-only scripts/configuration under `swift/`; keep Gradle files at root
when the wrapper or both Android modules consume them.

## Verification

Use the `verify-build` skill for repository-wide changes, `verify-android` for Android-only work,
and the Swift matrix in `verify-build` for Apple-only work.

Validate the manifest with `swift package dump-package`, then build and test with Xcode 26 or newer.
The package uses Xcode-generated string-catalog symbols, which the `swift build` CLI does not
generate, and `swift test` cannot load VLCKit from the test bundle. Conditional code means Apple
changes must build and test on macOS, iOS, and tvOS. Resolve destinations with
`swift/Scripts/xcode-destination.sh`; do not hard-code simulator names.

Android uses JDK 17, compile/target SDK 37, min SDK 23, and the checked-in wrapper. `:app` has a
`source` flavor dimension (`local` builds against `project(":vlc-player")`, `maven` against the
published `io.github.dooop:vlc-player` GitHub Packages artifact); the `maven` flavor needs
`read:packages` credentials (`gpr.user`/`gpr.key` in `~/.gradle/gradle.properties`, or
`GITHUB_ACTOR`/`GITHUB_TOKEN`). The baseline Android verification is:

```bash
./gradlew :app:assembleLocalDebug :vlc-player:assembleRelease \
  :vlc-player:lintDebug :vlc-player:testDebugUnitTest ktlintCheck
```

## Swift rules

- `VLC` re-exports `VLCKit`, `MobileVLCKit`, or `TVVLCKit`; `VLCPlayer` is the SwiftUI product.
- Maintain strict Swift 6 concurrency. `PlayerViewModel` is `@MainActor`; nonisolated delegate
  callbacks hop back with `Task { @MainActor in ... }`.
- Prefer platform compile conditions. macOS uses `NSViewControllerRepresentable`; iOS/tvOS use
  `UIViewControllerRepresentable`. tvOS has a custom slider and focus behavior.
- Keep types internal unless intentionally changing the public API.
- Use Swift Testing, never network/playback in tests, and preserve Swift file header style.
- Format with `swift/.swift-format`; see `verify-build` for the exact command.

Swift localization lives in
`swift/Sources/VLCPlayer/UI/Resources/Localizable.xcstrings`. Xcode generates typed symbols for its
keys, covered by `swift/Tests/VLCPlayerTests/LocalizationTests.swift`. Use the
`add-localized-string` skill.

## Android rules

- Use the `android-development` skill for architecture and implementation conventions.
- Keep the public Compose entry point in package `org.videolan.vlcplayer`; sample-only code stays in
  `org.videolan.vlcplayer.sample`.
- `VLCPlayer` owns its controller/LibVLC lifecycle. Release native resources deterministically and
  keep lifecycle, saved-position, screen-on, and control-auto-hide behavior intact.
- Use Compose state/effects rather than retaining Activity/View references. Keep blocking or native
  operations away from composition.
- Put library resources under `android/vlc-player/src/main/res`; sample resources belong to
  `android/app/src/main/res`. Use the `add-android-localized-string` skill for UI text.
- Keep dependency versions in `gradle/libs.versions.toml`, not scattered through module files.
- Format Kotlin with ktlint (`org.jlleitschuh.gradle.ktlint`, applied to `:app` and `:vlc-player`).
  Run `./gradlew ktlintFormat` locally and `./gradlew ktlintCheck` before finishing, matching CI.

## VLCKit release assets

`Package.swift` points to xcframework zip files attached to this repository's GitHub releases.
Upstream inputs live in `swift/Scripts/vlc-frameworks.conf`. Re-zipping is not byte-reproducible, so
the manifest checksum must come from the archive actually uploaded. Use `update-vlckit` before
changing those targets and `release` when publishing.

The Android release asset is named `vlc-player-android-<version>.aar`.

## Style and commits

- Never hard-code user-facing strings on either platform.
- Keep platform-specific documentation in the corresponding platform README and cross-platform
  orientation in the root README.
- Follow Conventional Commits (`feat:`, `fix:`, `docs:`, optional scope).

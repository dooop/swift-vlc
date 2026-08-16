# VLC Player

[![CI](https://github.com/dooop/swift-vlc/actions/workflows/ci.yml/badge.svg)](https://github.com/dooop/swift-vlc/actions/workflows/ci.yml)

VLC Player provides native, reusable video players backed by VideoLAN for Apple platforms and
Android. The Apple implementation is distributed through Swift Package Manager; the Android
implementation is a Jetpack Compose library backed by LibVLC.

## Platforms

| Platform | UI | VLC integration | Minimum version |
| --- | --- | --- | --- |
| macOS | SwiftUI | VLCKit | macOS 15 |
| iOS | SwiftUI | MobileVLCKit | iOS 18 |
| tvOS | SwiftUI | TVVLCKit | tvOS 18 |
| Android | Jetpack Compose | LibVLC | Android 6.0 / API 23 |

## Repository layout

- `Package.swift` — root Swift package manifest, kept at the repository root for remote SwiftPM
  dependencies
- `swift/` — Swift sources, tests, framework tooling, formatting configuration, and
  [Swift-specific documentation](swift/README.md)
- `android/` — Android library, sample app, and
  [Android-specific documentation](android/README.md)
- `gradle/`, `gradlew`, and root Gradle files — shared Android build configuration and wrapper

## Swift Package

Add the package dependency and select either the low-level `VLC` product or the ready-to-use
`VLCPlayer` SwiftUI product:

```swift
dependencies: [
  .package(url: "https://github.com/dooop/swift-vlc", from: "0.3.1")
]
```

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "VLCPlayer", package: "swift-vlc")
  ]
)
```

See [swift/README.md](swift/README.md) for usage, local framework tooling, platform behavior, and
the complete Apple build/test workflow.

## Android Library

From a source checkout, depend on the library module:

```kotlin
dependencies {
    implementation(project(":vlc-player"))
}
```

Each release publishes the Android library as `io.github.dooop:vlc-player:<version>` in GitHub
Packages. It also attaches the standalone AAR and a downloadable Maven-repository zip to the GitHub
release. See [android/README.md](android/README.md) for repository setup, Compose usage, sample-app
commands, localization, and Android verification.

## Creating a release

Run the **Release** workflow from GitHub Actions and enter a version such as `0.5.0` (without a `v`
prefix). After all Apple and Android checks pass, the workflow:

1. creates an annotated tag for the selected commit,
2. creates or publishes the GitHub release with generated notes,
3. uploads both `vlc-player-android-<version>.aar` and
   `vlc-player-maven-<version>.zip` as release assets, and
4. publishes `io.github.dooop:vlc-player:<version>` to GitHub Packages.

Pushing a matching SemVer tag manually remains supported and runs the same verification and publish
steps. Versions are immutable: do not reuse a version after it has been published to GitHub
Packages.

## Development checks

Run the platform-specific checks documented in the two platform READMEs. The short Android suite
is:

```bash
./gradlew :app:assembleDebug :vlc-player:assembleRelease \
  :vlc-player:lintDebug :vlc-player:testDebugUnitTest
```

CI runs formatting, manifest validation, Apple builds/tests for macOS, iOS, and tvOS, and Android
build/lint/unit-test checks on every push and pull request.

## Credits and license

Built on VideoLAN's [VLCKit](https://github.com/videolan/vlckit) and
[LibVLC for Android](https://code.videolan.org/videolan/libvlc-android-samples).

See [LICENSE](LICENSE) for this project's license. Refer to the upstream VideoLAN projects for
their licensing and distribution terms.

# swift-vlc

[![CI](https://github.com/dooop/swift-vlc/actions/workflows/ci.yml/badge.svg)](https://github.com/dooop/swift-vlc/actions/workflows/ci.yml)

Swift Package wrapper for VideoLAN's [VLCKit](https://github.com/videolan/vlckit) `xcframework`s with an optional SwiftUI player UI, plus a matching Android AAR built with Jetpack Compose and LibVLC.

This package exposes:

- `VLC`: a thin module that re-exports the platform-specific VLCKit module (`VLCKit`, `MobileVLCKit`, or `TVVLCKit`)
- `VLCPlayer`: a SwiftUI `VLCPlayer(url:)` view that manages an internal `VLCMediaPlayer` and shows built-in playback controls
- `vlc-player`: a Compose `VLCPlayer(url:)` component with the same ownership, lifecycle, resume, and controls model backed by LibVLC

## Supported Platforms

- macOS 15+
- iOS 18+
- tvOS 18+
- Android 6.0+ (API 23)

## Project Layout

- `Sources/VLC`: re-export layer for the underlying VLCKit framework
- `Sources/VLCPlayer`: SwiftUI player implementation (rendering host, controls, state/view model)
- `Tests/`: Swift Testing suites for the VLCKit linkage and the player model/localization
- `Frameworks/*.xcframework`: local xcframework copies for inspection and for building the release assets (git-ignored, not referenced by `Package.swift`)
- `Scripts/update-vlc-frameworks.sh`: downloads/extracts/installs VLCKit `xcframework`s for local development
- `Scripts/package-vlc-frameworks.sh`: repackages them as the `.xcframework.zip` release assets
- `Scripts/xcode-destination.sh`: resolves an `xcodebuild -destination` per platform
- `Scripts/vlc-frameworks.conf`: configurable archive URLs and recorded SHA-256 checksums
- `android/vlc-player`: Android library module producing the Compose/LibVLC AAR

## Requirements

- Xcode 16 or newer with a Swift 6 toolchain (`swift-tools-version: 6.0`)
- Android Studio or JDK 17 plus Android SDK 36 for the Android library (the checked-in Gradle wrapper installs Gradle itself)

## Installation

### Swift Package Manager (remote)

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/dooop/swift-vlc", from: "0.3.1")
]
```

The VLCKit `xcframework`s are fetched automatically as remote binary targets — no manual download step is required.

### Local package dependency (development)

```swift
dependencies: [
  .package(path: "../swift-vlc")
]
```

When working on this package locally, use the helper script to download the `xcframework`s into `Frameworks/` before building:

```bash
./Scripts/update-vlc-frameworks.sh
```

What it does:

- reads `Scripts/vlc-frameworks.conf`
- downloads each archive URL
- extracts the matching `*.xcframework`
- copies it into `Frameworks/`
- updates the third config column with the archive SHA-256 checksum

Config file format:

```text
<framework-name>|<archive-url>|<sha256>
```

Optional usage:

```bash
# Use a different config file
./Scripts/update-vlc-frameworks.sh /path/to/vlc-frameworks.conf

# Override the destination Frameworks folder
FRAMEWORKS_DIR=/path/to/Frameworks ./Scripts/update-vlc-frameworks.sh
```

### Products

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "VLC", package: "swift-vlc"),
    // or
    .product(name: "VLCPlayer", package: "swift-vlc"),
  ]
)
```

Use `VLC` if you only need the raw VLCKit APIs. Use `VLCPlayer` for the built-in SwiftUI player UI — it already re-exports `VLC`, so you do not need to add both.

## Usage

### Core VLCKit API (`VLC`)

```swift
import VLC

let player = VLCMediaPlayer()
let media = VLCMedia(url: URL(string: "https://example.com/video.mp4")!)

player.media = media
player.play()
```

### SwiftUI Player (`VLCPlayer`)

`VLCPlayer` is a ready-to-use SwiftUI player that takes a media URL and manages playback lifecycle internally. Importing `VLCPlayer` also exposes the full `VLC` module via re-export.

```swift
import SwiftUI
import VLCPlayer

struct ContentView: View {
  let url = URL(string: "https://example.com/video.mp4")!

  var body: some View {
    VLCPlayer(url: url)
  }
}
```

### Jetpack Compose Player (Android)

For a source checkout, use the Gradle project at the repository root and depend on `:vlc-player`.
The public component mirrors the SwiftUI initializer:

```kotlin
import android.net.Uri
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import org.videolan.vlcplayer.VLCPlayer

@Composable
fun PlayerScreen() {
    VLCPlayer(
        url = Uri.parse("https://example.com/video.mp4"),
        modifier = Modifier.fillMaxSize(),
    )
}
```

Each GitHub release contains `swift-vlc-android-<version>.aar`. It is a standard thin AAR; when
using that file directly rather than the Gradle module, the consuming app must also declare its
runtime dependencies:

```kotlin
dependencies {
    implementation(files("libs/swift-vlc-android-0.4.0.aar"))
    implementation(platform("androidx.compose:compose-bom:2026.06.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.10.0")
    implementation("org.videolan.android:libvlc-all:3.7.5")
}
```

The Android component accepts an optional `subtitleScale` percentage (default `100`). It owns and
releases LibVLC internally, just as the SwiftUI component owns its `VLCMediaPlayer`.

The repository also includes a small runnable sample application in `android/app`. Open the root
project in Android Studio and run the `app` configuration, or build its debug APK from the command
line:

```bash
./gradlew :app:assembleDebug
```

The app accepts HTTP(S), RTSP, RTMP, file, and content URIs and starts with a public sample video.

## Development

`swift build` works, but **`swift test` does not** — SwiftPM does not embed the VLCKit binary
framework into the xctest bundle, so the test bundle fails to load. Run the tests with `xcodebuild`.

```bash
# compile for every platform
for platform in macos ios tvos; do
  xcodebuild build -scheme swift-vlc-Package \
    -destination "$(Scripts/xcode-destination.sh "$platform" build)" \
    -derivedDataPath .derivedData -quiet
done

# run the tests (macOS, iOS Simulator, tvOS Simulator)
for platform in macos ios tvos; do
  xcodebuild test -scheme swift-vlc-Package \
    -destination "$(Scripts/xcode-destination.sh "$platform")" \
    -derivedDataPath .derivedData -quiet
done

# formatting
xcrun swift-format format --in-place --recursive Sources Tests Package.swift

# Android sample app, AAR, lint, and unit tests (from the repository root)
./gradlew :app:assembleDebug :vlc-player:assembleRelease :vlc-player:lintDebug :vlc-player:testDebugUnitTest
```

`Scripts/xcode-destination.sh` resolves a concrete simulator UDID from the newest installed runtime,
so nothing depends on a simulator name that only exists in one Xcode version.

The player UI uses String Catalog symbols (`.audio`, `.cancel`, …). Xcode generates those from
`Localizable.xcstrings`, SwiftPM does not — `Sources/VLCPlayer/UI/LocalizedStrings.swift` mirrors
them behind `#if !Xcode` so both build systems work. A new catalog key has to be added in both
places.

The same steps run in CI (`.github/workflows/ci.yml`) on every push and pull request. Tagged release
builds also attach the versioned Android AAR to the GitHub release.

## Notes

- `VLCPlayer` includes built-in controls: play/pause/restart, seek slider, current/remaining timestamps, and audio/subtitle track selection when streams are available.
- Playback positions are persisted per URL via `@AppStorage` so playback resumes where it left off.
- `VLCPlayer` responds to scene phase changes: playback pauses when the scene becomes inactive (a notification banner, Control Center, a macOS window losing focus) and resumes when it becomes active. Real backgrounding releases the player and persists the position; returning reloads and resumes where it left off.
- Platform-specific behaviour: on iOS/tvOS the idle sleep timer is disabled while playback is running (independently of whether the controls are visible); on macOS the cursor is hidden while the controls are hidden; the tvOS play/pause hardware command and the macOS spacebar toggle playback.
- `VLCPlayer` owns its `VLCMediaPlayer` instance. If you need direct player configuration or delegate callbacks, build your own UI using the `VLC` product.
- The Android `VLCPlayer` includes the same play/pause/restart, seek, current/remaining time,
  audio/subtitle selection, five-second control auto-hide, per-URI position persistence, screen-on,
  and lifecycle behavior as the SwiftUI implementation.

## Credits

- Built on top of VideoLAN's [VLCKit](https://github.com/videolan/vlckit)

## License

See [LICENSE](LICENSE) for this wrapper package. Refer to VLCKit for upstream framework licensing and distribution terms.

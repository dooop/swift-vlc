# swift-vlc

Swift Package wrapper for VideoLAN's [VLCKit](https://github.com/videolan/vlckit) `xcframework`s with an optional SwiftUI player UI.

This package exposes:

- `VLC`: a thin module that re-exports the platform-specific VLCKit module (`VLCKit`, `MobileVLCKit`, or `TVVLCKit`)
- `VLCPlayer`: a SwiftUI `VLCPlayer(url:)` view that manages an internal `VLCMediaPlayer` and shows built-in playback controls

## Supported Platforms

- macOS 15+
- iOS 18+
- tvOS 18+

## Project Layout

- `Sources/VLC`: re-export layer for the underlying VLCKit framework
- `Sources/VLCPlayer`: SwiftUI player implementation (rendering host, controls, state/view model)
- `Frameworks/*.xcframework`: local xcframework copies used during development
- `Scripts/update-vlc-frameworks.sh`: downloads/extracts/installs VLCKit `xcframework`s for local development
- `Scripts/vlc-frameworks.conf`: configurable archive URLs and recorded SHA-256 checksums

## Requirements

- Xcode with a Swift 6 toolchain (`swift-tools-version: 6.0`)

## Installation

### Swift Package Manager (remote)

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/dooop/swift-vlc", from: "0.2.0")
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

## Notes

- `VLCPlayer` includes built-in controls: play/pause/restart, seek slider, current/remaining timestamps, and audio/subtitle track selection when streams are available.
- Playback positions are persisted per URL via `@AppStorage` so playback resumes where it left off.
- `VLCPlayer` responds to scene phase changes: playback pauses when the scene becomes inactive and resumes when it becomes active again.
- Platform-specific behaviour: the idle sleep timer is disabled on iOS/tvOS during playback; the cursor is hidden on macOS; the tvOS play/pause hardware command and macOS spacebar are wired to toggle playback.
- `VLCPlayer` owns its `VLCMediaPlayer` instance. If you need direct player configuration or delegate callbacks, build your own UI using the `VLC` product.

## Credits

- Built on top of VideoLAN's [VLCKit](https://github.com/videolan/vlckit)

## License

See [LICENSE](LICENSE) for this wrapper package. Refer to VLCKit for upstream framework licensing and distribution terms.

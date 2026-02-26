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
- `Frameworks/*.xcframework`: local binary dependencies used by SwiftPM
- `Scripts/update-vlc-frameworks.sh`: downloads/extracts/install VLCKit `xcframework`s
- `Scripts/vlc-frameworks.conf`: configurable archive URLs and recorded SHA-256 checksums

## Requirements

- Xcode with a Swift 6 toolchain (`swift-tools-version: 6.0`)
- The VLCKit `xcframework`s present in `Frameworks/`

Expected framework paths:

- `Frameworks/VLCKit.xcframework`
- `Frameworks/MobileVLCKit.xcframework`
- `Frameworks/TVVLCKit.xcframework`

## Installation

### Fetch / refresh VLCKit frameworks

This package uses local `binaryTarget(path:)` entries, so the `xcframework`s must exist in `Frameworks/` before building.

Use the helper script to download and install them:

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

### Local package dependency

```swift
dependencies: [
  .package(path: "../swift-vlc")
]
```

### Products

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "VLC", package: "swift-vlc"),
    .product(name: "VLCPlayer", package: "swift-vlc"),
  ]
)
```

Use only `VLC` if you just need the VLCKit APIs. Use `VLCPlayer` for the built-in SwiftUI player UI (and add `VLC` too if your app imports `VLC` directly).

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

`VLCPlayer` is a ready-to-use SwiftUI player that takes a media URL and manages playback lifecycle internally.

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

- SwiftPM will not auto-run the helper script on package resolve; run `./Scripts/update-vlc-frameworks.sh` yourself when you need to install or refresh the local `xcframework`s.
- `VLCPlayer` includes built-in controls (play/pause/restart, seek slider, timestamps, audio/subtitle track selection when available).
- `VLCPlayer` owns its `VLCMediaPlayer` instance. If you need direct player configuration/delegates, build your own UI using the `VLC` product.

## Credits

- Built on top of VideoLAN's [VLCKit](https://github.com/videolan/vlckit)

## License

See [LICENSE](LICENSE) for this wrapper package. Refer to VLCKit for upstream framework licensing and distribution terms.

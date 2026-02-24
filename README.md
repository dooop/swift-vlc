# swift-vlc

Swift Package wrapper for VideoLAN's [VLCKit](https://github.com/videolan/vlckit) `xcframework`s.

This package exposes:

- `VLC`: a thin module that re-exports the platform-specific VLCKit module (`VLCKit`, `MobileVLCKit`, or `TVVLCKit`)
- `VLCPlayer`: a SwiftUI `VLCPlayerView` that binds a `VLCMediaPlayer` to a native view controller

## Supported Platforms

- macOS 10.15+
- iOS 13+
- tvOS 13+

## Project Layout

- `Sources/VLC`: re-export layer for the underlying VLCKit framework
- `Sources/VLCPlayer`: SwiftUI wrapper view for `VLCMediaPlayer`
- `Frameworks/*.xcframework`: local binary dependencies used by SwiftPM

## Requirements

- Xcode with a Swift 6 toolchain (`swift-tools-version: 6.0`)
- The VLCKit `xcframework`s present in `Frameworks/`

Expected framework paths:

- `Frameworks/VLCKit.xcframework`
- `Frameworks/MobileVLCKit.xcframework`
- `Frameworks/TVVLCKit.xcframework`

## Installation

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

Use only `VLC` if you just need the VLCKit APIs. Add `VLCPlayer` if you want the SwiftUI wrapper view.

## Usage

### Core VLCKit API (`VLC`)

```swift
import VLC

let player = VLCMediaPlayer()
let media = VLCMedia(url: URL(string: "https://example.com/video.mp4")!)

player.media = media
player.play()
```

### SwiftUI Player View (`VLCPlayer`)

`VLCPlayerView` renders the video output of an existing `VLCMediaPlayer`. You manage playback lifecycle outside the view.

```swift
import SwiftUI
import VLC
import VLCPlayer

struct ContentView: View {
  @State private var player = VLCMediaPlayer()

  var body: some View {
    VLCPlayerView(player: player)
      .onAppear {
        player.media = VLCMedia(url: URL(string: "https://example.com/video.mp4")!)
        player.play()
      }
      .onDisappear {
        player.stop()
      }
  }
}
```

## Notes

- This package does not download VLCKit binaries for you; it expects local `xcframework`s in `Frameworks/`.
- `VLCPlayerView` is a minimal drawable host. Configure `VLCMediaPlayer` (delegate, options, media, playback state) in your own code.

## Credits

- Built on top of VideoLAN's [VLCKit](https://github.com/videolan/vlckit)

## License

See [LICENSE](LICENSE) for this wrapper package. Refer to VLCKit for upstream framework licensing and distribution terms.

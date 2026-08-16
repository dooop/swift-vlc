# VLC Player for Swift

The Swift package provides two library products for macOS 15+, iOS 18+, and tvOS 18+:

- `VLC` re-exports upstream VLCKit 4's unified `VLCKit` module, which now covers macOS, iOS, and
  tvOS from a single binary (VLCKit 4 dropped the separate `MobileVLCKit`/`TVVLCKit` modules).
- `VLCPlayer` provides a SwiftUI `VLCPlayer(url:)` with playback controls and re-exports `VLC`.

The manifest remains at [`../Package.swift`](../Package.swift), while all Swift source, tests,
tooling, and formatting configuration live in this directory.

## Installation

```swift
dependencies: [
  .package(url: "https://github.com/dooop/swift-vlc", from: "0.3.1")
]
```

```swift
.target(
  name: "MyApp",
  dependencies: [
    .product(name: "VLC", package: "swift-vlc"),
    // Or use the SwiftUI player:
    .product(name: "VLCPlayer", package: "swift-vlc")
  ]
)
```

For a local checkout, reference the repository root because that is where `Package.swift` lives:

```swift
.package(path: "../vlc-player")
```

`Package.swift` depends on upstream [VLCKit](https://github.com/videolan/vlckit)'s own Swift
package, which resolves its universal xcframework as a remote binary target automatically.

## Usage

Use the raw VLCKit API:

```swift
import VLC

let player = VLCMediaPlayer()
player.media = VLCMedia(url: URL(string: "https://example.com/video.mp4")!)
player.play()
```

Or use the managed SwiftUI player:

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

`VLCPlayer` owns its `VLCMediaPlayer`, persists playback position per URL, reacts to app lifecycle
changes, manages the idle timer/cursor where appropriate, and includes seek, playback, audio-track,
and subtitle-track controls.

## Layout

- `swift/Sources/VLC/` — unified VLCKit re-export
- `swift/Sources/VLCPlayer/` — SwiftUI player, view model, models, views, and string catalog
- `swift/Tests/` — Swift Testing suites
- `swift/Scripts/xcode-destination.sh` — resolves portable Xcode destinations

## Development

Run all commands from the repository root with Xcode 26 or newer. Validate the SwiftPM manifest
directly, then build and test through `xcodebuild`; generated string-catalog symbols are an Xcode
build feature, and `swift test` cannot load the embedded VLCKit framework:

```bash
swift package dump-package

for platform in macos ios tvos; do
  xcodebuild build -scheme swift-vlc-player-Package \
    -destination "$(swift/Scripts/xcode-destination.sh "$platform" build)" \
    -derivedDataPath .derivedData -quiet
done

for platform in macos ios tvos; do
  xcodebuild test -scheme swift-vlc-player-Package \
    -destination "$(swift/Scripts/xcode-destination.sh "$platform")" \
    -derivedDataPath .derivedData -quiet
done

xcrun swift-format lint --configuration swift/.swift-format \
  --recursive --strict swift/Sources swift/Tests Package.swift
```

Xcode generates `LocalizedStringResource` symbols directly from
`swift/Sources/VLCPlayer/UI/Resources/Localizable.xcstrings`. Add each new key to that catalog and
the localization tests, then use the generated member such as `.audio` in source code.

## Bumping VLCKit

`Package.swift`'s `dependencies` array pins an `exact` upstream VLCKit tag (VLCKit 4 alphas are not
semver-ordered in a way `from:`/`upToNextMajor` can safely track). To move to a newer tag, update
that version string and re-resolve; upstream owns the binary target, its archive, and its checksum,
so there is nothing to repackage or re-upload in this repository.

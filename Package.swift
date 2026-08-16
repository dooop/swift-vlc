// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "swift-vlc-player",
  defaultLocalization: "en",
  platforms: [
    .macOS(.v15), .iOS(.v18), .tvOS(.v18),
  ],
  products: [
    .library(
      name: "VLC",
      targets: ["VLC"]
    ),
    .library(
      name: "VLCPlayer",
      targets: ["VLCPlayer"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/videolan/vlckit", exact: "4.0.0-a23")
  ],
  targets: [
    .target(
      name: "VLC",
      dependencies: [
        .product(name: "VLCKit", package: "vlckit")
      ],
      path: "swift/Sources/VLC",
      linkerSettings: [
        .linkedFramework("AudioToolbox"),
        .linkedFramework("AVFoundation"),
        .linkedFramework("CFNetwork"),
        .linkedFramework("CoreFoundation"),
        .linkedFramework("CoreGraphics"),
        .linkedFramework("CoreMedia"),
        .linkedFramework("CoreText"),
        .linkedFramework("CoreVideo"),
        .linkedFramework("Foundation"),
        .linkedFramework("QuartzCore"),
        .linkedFramework("Security"),
        .linkedFramework("VideoToolbox"),
        .linkedFramework("OpenGLES", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
        .linkedLibrary("c++"),
        .linkedLibrary("xml2"),
        .linkedLibrary("z"),
        .linkedLibrary("bz2"),
        .linkedLibrary("iconv"),
      ]
    ),
    .target(
      name: "VLCPlayer",
      dependencies: ["VLC"],
      path: "swift/Sources/VLCPlayer",
      resources: [.process("UI/Resources")]
    ),
    .testTarget(
      name: "VLCTests",
      dependencies: ["VLC"],
      path: "swift/Tests/VLCTests"
    ),
    .testTarget(
      name: "VLCPlayerTests",
      dependencies: ["VLCPlayer"],
      path: "swift/Tests/VLCPlayerTests"
    ),
  ]
)

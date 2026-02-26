// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "swift-vlc",
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
  dependencies: [],
  targets: [
    .target(
      name: "VLC",
      dependencies: [
        .target(name: "VLCKit", condition: .when(platforms: [.macOS])),
        .target(name: "MobileVLCKit", condition: .when(platforms: [.iOS])),
        .target(name: "TVVLCKit", condition: .when(platforms: [.tvOS])),
      ],
      linkerSettings: [
        .linkedFramework("QuartzCore", .when(platforms: [.iOS])),
        .linkedFramework("CoreText", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("AVFoundation", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("Security", .when(platforms: [.iOS])),
        .linkedFramework("CFNetwork", .when(platforms: [.iOS])),
        .linkedFramework("AudioToolbox", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("OpenGLES", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("CoreGraphics", .when(platforms: [.iOS])),
        .linkedFramework("VideoToolbox", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("CoreMedia", .when(platforms: [.iOS, .tvOS])),
        .linkedLibrary("c++", .when(platforms: [.iOS, .tvOS])),
        .linkedLibrary("xml2", .when(platforms: [.iOS, .tvOS])),
        .linkedLibrary("z", .when(platforms: [.iOS, .tvOS])),
        .linkedLibrary("bz2", .when(platforms: [.iOS, .tvOS])),
        .linkedFramework("Foundation", .when(platforms: [.macOS])),
        .linkedLibrary("iconv"),
      ]
    ),
    .target(
      name: "VLCPlayer",
      dependencies: ["VLC"],
    ),
    .binaryTarget(
      name: "VLCKit",
      path: "Frameworks/VLCKit.xcframework"
    ),
    .binaryTarget(
      name: "MobileVLCKit",
      path: "Frameworks/MobileVLCKit.xcframework"
    ),
    .binaryTarget(
      name: "TVVLCKit",
      path: "Frameworks/TVVLCKit.xcframework"
    ),
  ]
)

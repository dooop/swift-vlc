// swift-tools-version:6.0
import PackageDescription

let binaryBaseURL = "https://github.com/dooop/swift-vlc/releases/download/0.3.0/"

let package = Package(
  name: "swift-vlc",
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
      resources: [.process("UI/Resources")]
    ),
    .binaryTarget(
      name: "VLCKit",
      url: "\(binaryBaseURL)VLCKit.xcframework.zip",
      checksum: "da97059039cc2a4f6d19cfa0e5facab8259ee8430510a19ac34314b1fd55a729"
    ),
    .binaryTarget(
      name: "MobileVLCKit",
      url: "\(binaryBaseURL)MobileVLCKit.xcframework.zip",
      checksum: "805c1e609f5dea9c62ac69539348254a2c73b1134e8370a0d5b31dc0b610504f"
    ),
    .binaryTarget(
      name: "TVVLCKit",
      url: "\(binaryBaseURL)TVVLCKit.xcframework.zip",
      checksum: "526b00c8dcc0577183d449b508d642dd6f1c63fe4da5264e1d238a529ff173f9"
    ),
  ]
)

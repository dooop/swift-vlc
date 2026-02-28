// swift-tools-version:6.0
import PackageDescription

let binaryBaseURL = "https://github.com/dooop/swift-vlc/releases/download/0.1.0/"

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
      checksum: "5b475cc6fa3c1d56d71af26efad247076690f608fd7fa103b33bf980736d5971"
    ),
    .binaryTarget(
      name: "MobileVLCKit",
      url: "\(binaryBaseURL)MobileVLCKit.xcframework.zip",
      checksum: "e34563249ac1b1045eaeff9a3172640e22e0e9f66b806b020d885bf7f346f4f3"
    ),
    .binaryTarget(
      name: "TVVLCKit",
      url: "\(binaryBaseURL)TVVLCKit.xcframework.zip",
      checksum: "370b14b48b39591b11d009ba959e2c6d342034b774270b8d18de3591dc80884d"
    ),
  ]
)

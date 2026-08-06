//
//  LocalizedStrings.swift
//  swift-vlc
//
//  Xcode's build system generates these members from `Localizable.xcstrings`
//  into `GeneratedStringSymbols_Localizable.swift`. SwiftPM's own build does not
//  run that generator, so `swift build` would fail with
//  "type 'LocalizedStringResource' has no member 'audio'".
//
//  This hand-written mirror fills that gap and is compiled *only* by SwiftPM:
//  Xcode defines the `Xcode` compilation condition, so under `xcodebuild` the
//  generated file stays the single source of truth and there is no redeclaration.
//
//  When adding a key to the catalog, add it here too — the mismatch is caught by
//  `Tests/VLCPlayerTests/LocalizationTests.swift`, which is built by xcodebuild
//  against the generated symbols.
//

#if !Xcode

  import Foundation

  extension LocalizedStringResource {
    private static var catalog: BundleDescription {
      .atURL(Bundle.module.bundleURL)
    }

    private static func localizable(_ key: String.LocalizationValue) -> LocalizedStringResource {
      LocalizedStringResource(key, table: "Localizable", bundle: catalog)
    }

    static var audio: LocalizedStringResource { localizable("Audio") }
    static var cancel: LocalizedStringResource { localizable("Cancel") }
    static var changeAudioTrack: LocalizedStringResource { localizable("Change Audio Track") }
    static var changeSubtitleTrack: LocalizedStringResource { localizable("Change Subtitle Track") }
    static var disable: LocalizedStringResource { localizable("Disable") }
    static var subtitle: LocalizedStringResource { localizable("Subtitle") }
  }

#endif

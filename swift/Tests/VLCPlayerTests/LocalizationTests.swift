//
//  LocalizationTests.swift
//  vlc-player
//
//  Guards the String Catalog symbol generation: the `.audio`, `.cancel`, …
//  members only exist because Xcode generates them from
//  `UI/Resources/Localizable.xcstrings`. If that generation ever breaks, this
//  file stops compiling — which is exactly the signal we want in CI.
//

import Foundation
import Testing

@testable import VLCPlayer

@Suite("Localization")
struct LocalizationTests {
  @Test(
    "catalog keys resolve to non-empty strings",
    arguments: [
      LocalizedStringResource.audio,
      .cancel,
      .changeAudioTrack,
      .changeSubtitleTrack,
      .disable,
      .subtitle,
    ]
  )
  func catalogKeysResolve(key: LocalizedStringResource) {
    #expect(!String(localized: key).isEmpty)
  }

  @Test("the development language is bundled")
  func developmentLanguageIsBundled() {
    #expect(Bundle.module.localizations.contains("en"))
  }

  @Test("german localization is bundled")
  func germanLocalizationIsBundled() {
    #expect(Bundle.module.localizations.contains("de"))
  }
}

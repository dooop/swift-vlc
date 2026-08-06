---
name: add-localized-string
description: Add, change or translate a user-facing string in the VLCPlayer UI via the Localizable.xcstrings String Catalog. Use when adding new UI text, a new button/label/dialog, a new language, or when a `.someKey` localization symbol does not resolve.
---

# Add a localized string

All user-facing text of `VLCPlayer` lives in
`Sources/VLCPlayer/UI/Resources/Localizable.xcstrings`. Source language is `en`, currently also
translated to `de`. Never hard-code a display string in a view, and never add a `.strings` or
`.stringsdict` file next to the catalog.

## How the symbols work

Every key exists **twice** and both have to be updated:

1. Xcode's build system generates `LocalizedStringResource` members from the catalog into
   `GeneratedStringSymbols_Localizable.swift` (used by `xcodebuild`).
2. `Sources/VLCPlayer/UI/LocalizedStrings.swift` mirrors them by hand behind `#if !Xcode`, so
   `swift build` compiles too. Xcode defines the `Xcode` compilation condition, which is what keeps
   the two from colliding — never remove that guard.

The symbol name is the key, lower-camel-cased:

| Catalog key | Symbol |
| --- | --- |
| `Audio` | `.audio` |
| `Change Audio Track` | `.changeAudioTrack` |

Only `LocalizedStringResource` extensions are generated — **not** `LocalizedStringKey` and **not**
`String.LocalizationValue`. So use APIs that accept a `LocalizedStringResource`:

```swift
Text(.subtitle)                       // ✅
Button(.cancel, role: .cancel) { }    // ✅
String(localized: .disable)           // ✅
Text("Subtitle")                      // ❌ hard-coded, not localized
```

This generation only happens under `xcodebuild`, which is why `swift build` fails on this package —
see CLAUDE.md.

## Steps

1. Add the entry to `Localizable.xcstrings`. Keep the existing shape — keys sorted alphabetically,
   `"extractionState": "manual"` for keys that only exist in the catalog:

   ```json
   "Playback Speed" : {
     "extractionState" : "manual",
     "localizations" : {
       "de" : {
         "stringUnit" : {
           "state" : "translated",
           "value" : "Wiedergabegeschwindigkeit"
         }
       }
     }
   }
   ```

   The `en` value is the key itself and is not repeated. `shouldTranslate: false` is used for
   pass-through keys like `%@`.
2. Add the matching member to `Sources/VLCPlayer/UI/LocalizedStrings.swift`:

   ```swift
   static var playbackSpeed: LocalizedStringResource { localizable("Playback Speed") }
   ```

3. Use `.playbackSpeed` in the view.
4. Add the key to the `catalogKeysResolve` argument list in
   `Tests/VLCPlayerTests/LocalizationTests.swift` so a missing translation is caught by CI.
5. Build both ways — `swift build` covers the hand-written mirror, `xcodebuild` the generated
   symbols (`verify-build` skill). A key added to only one of them fails in the other.

## Adding a language

Add a `"<code>": { "stringUnit": … }` block under `localizations` for **every** key, and add a
`Bundle.module.localizations.contains("<code>")` assertion in `LocalizationTests`. `Package.swift`
already ships the catalog via `resources: [.process("UI/Resources")]`; `defaultLocalization` stays
`en`.

## Troubleshooting

- `type 'LocalizedStringResource' has no member 'x'` — key missing from the catalog, or built with
  `swift build`, or the camel-cased name differs from what was assumed (check the generated file
  under `.derivedData/.../DerivedSources/GeneratedStringSymbols_Localizable.swift`).
- Text shows the raw key at runtime — the key exists but has no translation for the active locale;
  falling back to the source language is expected behaviour.
- Accessibility labels count as user-facing text: `PlayerTrackButton` passes the localized title to
  `.accessibilityLabel(_:)`.

---
name: add-localized-string
description: Add, change or translate a user-facing string in the VLCPlayer UI via the Localizable.xcstrings String Catalog. Use when adding new UI text, a new button/label/dialog, a new language, or when a `.someKey` localization symbol does not resolve.
---

# Add a localized string

All user-facing Swift text of `VLCPlayer` lives in
`swift/Sources/VLCPlayer/UI/Resources/Localizable.xcstrings`. Source language is `en`, currently also
translated to `de`. Never hard-code a display string in a view, and never add a `.strings` or
`.stringsdict` file next to the catalog.

## How the symbols work

`Localizable.xcstrings` is the single source of truth. Xcode 26 generates a
`LocalizedStringResource` extension from its keys during the build.

The symbol name is the key, lower-camel-cased:

| Catalog key | Symbol |
| --- | --- |
| `Audio` | `.audio` |
| `Change Audio Track` | `.changeAudioTrack` |

Use the generated symbols with APIs that accept `LocalizedStringResource`:

```swift
Text(.subtitle)                       // ✅
Button(.cancel, role: .cancel) { }    // ✅
String(localized: .disable)           // ✅
Text("Subtitle")                     // ❌ bypasses the generated symbol
```

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
2. Use the generated `.playbackSpeed` symbol in the view.
3. Add the key to the `catalogKeysResolve` argument list in
   `swift/Tests/VLCPlayerTests/LocalizationTests.swift` so a missing translation is caught by CI.
4. Build with Xcode 26 (`verify-build` skill) to generate and compile the symbol.

## Adding a language

Add a `"<code>": { "stringUnit": … }` block under `localizations` for **every** key, and add a
`Bundle.module.localizations.contains("<code>")` assertion in `LocalizationTests`. `Package.swift`
already ships the catalog via `resources: [.process("UI/Resources")]`; `defaultLocalization` stays
`en`.

## Troubleshooting

- `type 'LocalizedStringResource' has no member 'x'` — ensure the key has Generate Swift Symbol
  enabled in the catalog, then build with Xcode 26 rather than `swift build`.
- Text shows the raw key at runtime — the key exists but has no translation for the active locale;
  falling back to the source language is expected behaviour.
- Accessibility labels count as user-facing text: `PlayerTrackButton` passes the localized title to
  `.accessibilityLabel(_:)`.

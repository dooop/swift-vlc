---
name: add-android-localized-string
description: Add, change, or translate user-facing Android VLC Player text through XML string resources. Use when editing Compose labels, buttons, accessibility descriptions, errors, adding a locale, fixing missing resource keys, or changing files under android/*/src/main/res/values*.
---

# Add an Android localized string

Place reusable player text in `android/vlc-player/src/main/res/values/strings.xml`. Put text used
only by the sample in `android/app/src/main/res/values/strings.xml`. Never make the sample own a
resource required by the library.

## Add or change a key

1. Add a descriptive `lower_snake_case` key to the module's default `values/strings.xml`.
2. Add the same key to every supported locale directory in that module, currently including
   `values-de` for the library. Preserve formatting placeholders exactly across translations.
3. Reference the resource in Compose with `stringResource(R.string.key)` or pass a resource ID to
   a non-composable API. Do not hard-code the fallback text in Kotlin.
4. Use `pluralStringResource` and `<plurals>` for quantities; use positional placeholders such as
   `%1$s` and `%2$d` when a string has multiple arguments.
5. Run:

   ```bash
   ./gradlew :vlc-player:lintDebug :vlc-player:testDebugUnitTest
   ```

   Also assemble `:app` when the sample resource set or integration changes.

## Add a locale

Create the Android-qualified resource directory for the locale and translate every user-facing key
from the default file. Keep non-translatable technical values marked `translatable="false"` in the
default file instead of copying them to locale folders. Run lint to detect missing or inconsistent
translations.

Content descriptions and accessibility labels are user-facing strings and follow the same rules.

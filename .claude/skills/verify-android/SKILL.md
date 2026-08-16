---
name: verify-android
description: Build, lint, and test the VLC Player Android library and sample app with the checked-in Gradle wrapper. Use before finishing Android or Gradle changes, when asked to compile/test/check Android, when CI's Android job fails, or when diagnosing Kotlin, Compose, resource, lint, SDK, or AAR failures.
---

# Verify Android

Run from the repository root with the checked-in wrapper. Require JDK 17 and Android SDK 37.

## Choose the check

Use a focused command while iterating:

```bash
./gradlew :vlc-player:testDebugUnitTest
./gradlew :vlc-player:assembleDebug
./gradlew :vlc-player:lintDebug
./gradlew :app:assembleDebug
./gradlew ktlintCheck
```

Before finishing an Android change, run the full CI-equivalent suite in one invocation:

```bash
./gradlew :app:assembleDebug :vlc-player:assembleRelease \
  :vlc-player:lintDebug :vlc-player:testDebugUnitTest ktlintCheck
```

For release-specific version wiring, add `-PreleaseVersion=X.Y.Z` and confirm the AAR at
`android/vlc-player/build/outputs/aar/vlc-player-release.aar`.

## Diagnose failures

- SDK/platform missing: compare module `compileSdk` with `.github/workflows/ci.yml` and install the
  same platform/build-tools combination locally.
- Dependency resolution or metadata mismatch: inspect `gradle/libs.versions.toml`, module dependency
  scopes, and Gradle's `dependencies`/`dependencyInsight` reports.
- Compose compiler error: check Kotlin and Compose plugin aliases remain aligned.
- Missing resource or translation: inspect both default and locale-specific `values/` files and use
  `add-android-localized-string`.
- Lint findings: read `android/vlc-player/build/reports/lint-results-debug.html` and fix the cause;
  do not add a blanket suppression or baseline without explicit authorization.
- ktlint findings: run `./gradlew ktlintFormat` to auto-fix, or read the reported file/line and
  fix the cause; do not disable rules without explicit authorization.
- Unit test details: inspect XML/HTML under `android/vlc-player/build/test-results` and
  `android/vlc-player/build/reports/tests`.

Report the exact Gradle tasks and whether each succeeded. Do not claim device/emulator behavior was
tested when only local JVM tests ran.

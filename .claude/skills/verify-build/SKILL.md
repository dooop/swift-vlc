---
name: verify-build
description: Build and test the complete VLC Player repository across macOS, iOS, tvOS, and Android. Use before finishing cross-platform or shared configuration changes, when asked to build/test/check everything, or when the affected platform is unclear. For Android-only changes, use verify-android.
---

# Verify the repository

Run commands from the repository root. Preserve the first failing command's exit status and report
exactly which platform checks ran.

## Swift package checks

Validate the manifest with SwiftPM, but do not run `swift build`: the package intentionally uses
Xcode-generated string-catalog symbols. Do not run `swift test` either, because SwiftPM does not
embed VLCKit in its xctest bundle. Use Xcode 26 or newer for builds and executable tests, and reuse
`.derivedData` so the large binary targets resolve once.

```bash
swift package dump-package

for platform in macos ios tvos; do
  xcodebuild build -scheme swift-vlc-player-Package \
    -destination "$(swift/Scripts/xcode-destination.sh "$platform" build)" \
    -derivedDataPath .derivedData -quiet
done

for platform in macos ios tvos; do
  xcodebuild test -scheme swift-vlc-player-Package \
    -destination "$(swift/Scripts/xcode-destination.sh "$platform")" \
    -derivedDataPath .derivedData -quiet
done

xcrun swift-format lint --configuration swift/.swift-format \
  --recursive --strict swift/Sources swift/Tests Package.swift
```

A Swift change is verified only after all three Apple destinations build and test. A checksum or
404 failure in a binary target belongs to the `update-vlckit` workflow.

## Android checks

Follow `verify-android` and run its full suite:

```bash
./gradlew :app:assembleDebug :vlc-player:assembleRelease \
  :vlc-player:lintDebug :vlc-player:testDebugUnitTest ktlintCheck
```

## Scope

- Root docs or agent-only changes: validate links/paths, the manifest, Gradle project discovery,
  and any changed skill; full native compilation is optional when no build input changed.
- `Package.swift`, `swift/`, or Apple workflow changes: run all Swift checks.
- Root Gradle files, `gradle/`, or `android/` changes: run all Android checks.
- Shared CI/release/layout changes: run both suites.

Filter verbose output only after capturing the command exit status. Never treat a pipeline ending
in `grep` or `tail` as the build result.

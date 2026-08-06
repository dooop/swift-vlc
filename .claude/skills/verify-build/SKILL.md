---
name: verify-build
description: Build and test swift-vlc across macOS, iOS and tvOS with xcodebuild. Use before finishing any source change, when asked to "build", "compile", "run the tests", "check it still works", or when a build failed and the cause is unclear. Also use when someone reports that `swift test` fails to load VLCKit.
---

# Verify a change across all platforms

`swift build` compiles and is fine as a quick syntax check, but **`swift test` cannot run** here —
SwiftPM does not embed the VLCKit binary framework into the xctest bundle, so it dies with
`Library not loaded: @loader_path/../Frameworks/VLCKit.framework/…`. Tests go through `xcodebuild`,
and so does any verification that a change actually works on iOS or tvOS.

## Commands

Destinations come from `Scripts/xcode-destination.sh` so nothing depends on a simulator name that
happens to exist on this machine.

```bash
# 1. compile for every platform (device slices, no simulator needed)
for p in macos ios tvos; do
  xcodebuild build -scheme VLCPlayer \
    -destination "$(Scripts/xcode-destination.sh "$p" build)" \
    -derivedDataPath .derivedData
done

# 2. build + run the test suites
for p in macos ios tvos; do
  xcodebuild test -scheme swift-vlc-Package \
    -destination "$(Scripts/xcode-destination.sh "$p")" \
    -derivedDataPath .derivedData
done

# 3. formatting
xcrun swift-format lint --recursive Sources Tests Package.swift
```

`xcodebuild` output is huge. Capture it and filter, e.g.:

```bash
out=$(xcodebuild test -scheme swift-vlc-Package -destination "$(Scripts/xcode-destination.sh ios)" -derivedDataPath .derivedData 2>&1)
echo "$out" | grep -E "error:|✘|Test run|BUILD (SUCCEEDED|FAILED)|TEST (SUCCEEDED|FAILED)" | sort -u
```

Never trust the shell exit status of a pipeline ending in `grep`/`tail` — check for the literal
`** BUILD SUCCEEDED **` / `** TEST SUCCEEDED **` marker instead.

## Timing

Cold run downloads ~700 MB of VLCKit binary targets and takes several minutes; budget generous
timeouts. Warm runs are well under a minute per platform. Reuse one `-derivedDataPath` across all
invocations so the binary targets are downloaded once.

## Reading failures

| Symptom | Cause |
| --- | --- |
| `type 'LocalizedStringResource' has no member 'x'` | key missing from `Localizable.xcstrings` (xcodebuild) or from `UI/LocalizedStrings.swift` (swift build) |
| `invalid redeclaration of 'x'` | the `#if !Xcode` guard in `UI/LocalizedStrings.swift` was removed or broken |
| `Library not loaded: … VLCKit.framework` | `swift test` was used; run tests with `xcodebuild` |
| `checksum of downloaded artifact ... does not match` | `Package.swift` disagrees with the published release asset → `update-vlckit` skill |
| `failed downloading … 404` | `binaryBaseURL` points at a tag whose release has no assets |
| Only tvOS fails, around focus or the seek bar | `Sources/VLCPlayer/UI/View/Slider.swift` — tvOS uses its own `UIViewRepresentable` slider |
| `No such module 'VLCKit'` on iOS/tvOS | wrong module for the platform; `Sources/VLC/VLC.swift` picks `MobileVLCKit`/`TVVLCKit` |

## Before reporting done

- All three platforms built **and** all three test destinations passed.
- `swift-format` produced no diff.
- Report what actually ran; if a platform was skipped, say so.

---
name: release
description: Cut a new VLC Player version for the Swift package and Android AAR — pre-flight checks, tag, and GitHub release. Use when asked to release, publish, ship, tag a version, or prepare release notes.
---

# Release VLC Player

Versions are plain `X.Y.Z` tags (no `v` prefix) — SwiftPM consumers resolve them directly.
`0.x` releases are marked as pre-releases on GitHub.

## Pre-flight

Never tag before these hold:

1. `main` is clean and up to date; the full Apple and Android build/test matrix passes
   (`verify-build` skill). A cold `swift package dump-package` / `xcodebuild` resolve is part of
   that matrix and validates the upstream VLCKit dependency's checksum — VLCKit hosts its own
   binary target now, so there is nothing of ours to check or repackage.
2. The root, Swift, and Android README version examples still make sense, and the release workflow
   produces `vlc-player-android-<version>.aar`.

## Cut it

```bash
git tag <version>
git push origin <version>
```

`.github/workflows/release.yml` then re-runs the whole matrix against the tag and creates the
GitHub release with generated notes (pre-release for `0.x`). If the workflow fails, delete the tag
locally and remotely, fix, re-tag — do not hand-edit the release.

## Release notes

Generated from Conventional Commit subjects since the previous tag. Worth adding by hand when
relevant:

- the VLCKit version, if it changed
- any deployment-target bump
- breaking changes to `VLCPlayer`'s public API

```bash
git log --oneline <previous-tag>..HEAD
```

## After

- `gh release view <version>` — assets and notes look right.
- Consuming a fresh checkout resolves: `swift package resolve` in a scratch package that depends on
  `.package(url: "https://github.com/dooop/swift-vlc", from: "<version>")`. This is the check that
  catches a wrong `binaryTarget` checksum, because SwiftPM verifies it while downloading.

## Do not

- Move or delete an existing tag — SwiftPM caches resolved versions and consumers will get checksum
  errors.
- Delete release assets of older tags; older versions of the package still reference them.
- Tag from a branch other than `main`.

---
name: update-vlckit
description: Bump the bundled VLCKit version (MobileVLCKit / TVVLCKit / VLCKit xcframeworks) end to end — new upstream tarballs, repackaged release assets, updated binaryTarget checksums in Package.swift. Use when asked to update VLC/VLCKit, upgrade to a new VLCKit version, or when a checksum mismatch on a binary target has to be fixed.
---

# Bump VLCKit

The package does not consume videolan.org tarballs directly: SwiftPM `binaryTarget`s only accept
zip, so the upstream `.tar.xz` archives are repackaged as `<Framework>.xcframework.zip` and attached
to a GitHub release of **this** repo. `binaryBaseURL` in `Package.swift` points at that release.

## The one rule that matters

`ditto -c -k` is **not** byte-reproducible — zipping the same xcframework twice yields different
checksums. So the checksum written into `Package.swift` must come from the archive that was
**actually uploaded**. Never re-zip locally and copy that checksum, and never "verify" a published
asset by rebuilding it.

Because of that, the order is always: build archives → upload → read checksums of the uploaded
files → update `Package.swift` → commit → tag.

## Preferred path: the workflow does it

`.github/workflows/vlckit-assets.yml` (`workflow_dispatch`) performs exactly that order and opens a
PR with the resulting `Package.swift`.

1. Find the new upstream URLs at <https://download.videolan.org/pub/cocoapods/prod/> — all three
   frameworks must be the same VLCKit version and build hash.
2. Update `swift/Scripts/vlc-frameworks.conf` (leave the checksum column as-is; the script rewrites it):

   ```text
   MobileVLCKit|https://download.videolan.org/pub/cocoapods/prod/MobileVLCKit-<version>-<hash>.tar.xz|
   TVVLCKit|https://download.videolan.org/pub/cocoapods/prod/TVVLCKit-<version>-<hash>.tar.xz|
   VLCKit|https://download.videolan.org/pub/cocoapods/prod/VLCKit-<version>-<hash>.tar.xz|
   ```

3. Commit that on a branch and push it.
4. Run the workflow with the target release tag (the version this package will publish next, e.g.
   `0.4.0`) and the branch. It downloads, repackages, uploads the assets to a **draft** release for
   that tag, reads back the uploaded checksums and opens a PR updating `binaryBaseURL` + all three
   `checksum:` values.
5. Review the PR, let CI pass, merge.
6. Then follow the `release` skill: tag the merge commit and publish the draft release.

## Manual path

Only if the workflow cannot be used. Needs ~2 GB of disk and a fast connection.

```bash
# 1. download upstream, install into swift/Frameworks/, refresh conf checksums
swift/Scripts/update-vlc-frameworks.sh

# 2. repackage into dist/*.xcframework.zip and print the SwiftPM checksums
swift/Scripts/package-vlc-frameworks.sh --no-download

# 3. upload to the (draft) release for the next tag
gh release create <tag> --draft --title <tag> --notes "" || true
gh release upload <tag> dist/*.xcframework.zip --clobber

# 4. read the checksums back from what is now published, and only then edit Package.swift
cat dist/checksums.txt
```

Then set `binaryBaseURL` to
`https://github.com/dooop/swift-vlc/releases/download/<tag>/` and paste each checksum into its
`binaryTarget`. `dist/` and `swift/Frameworks/` are git-ignored — do not commit them.

## Verify

A cold `xcodebuild` resolves the binary targets from the published URLs and validates the checksums
itself, so the real check is a clean build:

```bash
rm -rf .derivedData
# then the full matrix from the verify-build skill
```

Also confirm the upstream tarball checksums that `update-vlc-frameworks.sh` wrote into
`swift/Scripts/vlc-frameworks.conf` are committed — that file is the record of which upstream build the
release assets were made from.

## Gotchas

- Keep all three frameworks on the same VLCKit version; mixing versions across platforms has bitten
  this repo's users before.
- Deployment targets in `Package.swift` (macOS 15 / iOS 18 / tvOS 18) are independent of the VLCKit
  version — do not raise them just because a new VLCKit shipped.
- If a new VLCKit drops a platform slice (e.g. no more armv7), builds still succeed; only mention it.
- Do not delete old release assets: older tags of this package still point at them.

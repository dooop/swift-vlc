---
name: release
description: Cut a new swift-vlc version — pre-flight checks, tag, GitHub release. Use when asked to release, publish, ship or tag a version, or to prepare release notes for this package.
---

# Release swift-vlc

Versions are plain `X.Y.Z` tags (no `v` prefix) — SwiftPM consumers resolve them directly.
`0.x` releases are marked as pre-releases on GitHub.

## Pre-flight

Never tag before these hold:

1. `main` is clean and up to date; the full build+test matrix passes (`verify-build` skill).
2. `Package.swift`'s `binaryBaseURL` points at a tag whose GitHub release **has all three assets**:

   ```bash
   swift package dump-package \
     | jq -r '.targets[] | select(.type == "binary") | .url' \
     | while read -r url; do
         printf '%s -> %s\n' "$url" "$(curl -sSLo /dev/null -w '%{http_code}' "$url")"
       done
   ```

   All three must be `200`.
   - VLCKit unchanged since the last release → leave `binaryBaseURL` on the older tag. This is
     normal and intended (0.3.1 reuses 0.3.0's assets).
   - VLCKit changed → the assets for the new tag must already exist. Run the `update-vlckit` skill
     first; do not tag before its PR is merged.
3. The README's version examples still make sense.

## Cut it

```bash
git tag <version>
git push origin <version>
```

`.github/workflows/release.yml` then re-runs the whole matrix against the tag and creates the
GitHub release with generated notes (pre-release for `0.x`). If the workflow fails, delete the tag
locally and remotely, fix, re-tag — do not hand-edit the release.

If a draft release for this tag already exists because `update-vlckit` uploaded assets into it, the
workflow publishes that draft instead of creating a new one; its assets are kept.

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

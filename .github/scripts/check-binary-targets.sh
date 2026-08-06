#!/usr/bin/env bash
#
# Checks that every binaryTarget URL declared in Package.swift is actually
# published. A tag whose release is missing its xcframework zips breaks every
# consumer of that tag, and the SwiftPM error for it is hard to read — so fail
# here with a clear message instead.
#
# This does not download the archives; their checksums are validated by SwiftPM
# during the build jobs.

set -euo pipefail

failed=0
found=0

while read -r name url; do
  [[ -z "$name" ]] && continue
  found=$((found + 1))

  status="$(curl -sSL --retry 3 --retry-delay 2 -o /dev/null -w '%{http_code}' --head "$url" || echo "000")"

  if [[ "$status" == "200" ]]; then
    printf '  ok    %-16s %s\n' "$name" "$url"
  else
    printf '  FAIL  %-16s %s (HTTP %s)\n' "$name" "$url" "$status"
    echo "::error::binaryTarget '$name' is not published at $url (HTTP $status)"
    failed=1
  fi
done < <(
  swift package dump-package \
    | jq -r '.targets[] | select(.type == "binary") | "\(.name) \(.url)"'
)

if [[ "$found" -eq 0 ]]; then
  echo "::error::No binary targets found in Package.swift — did the manifest change shape?"
  exit 1
fi

if [[ "$failed" -ne 0 ]]; then
  cat <<'EOF'

The binaryBaseURL in Package.swift points at a release that does not carry the
xcframework archives. Either point it back at the last tag that has them, or
publish the assets first (see .github/workflows/vlckit-assets.yml).
EOF
  exit 1
fi

echo "All $found binary targets are published."

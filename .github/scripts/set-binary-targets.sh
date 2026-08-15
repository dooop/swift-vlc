#!/usr/bin/env bash
#
# Rewrites the binaryTarget coordinates in Package.swift:
#   - binaryBaseURL      -> the release the archives were uploaded to
#   - checksum: "…"      -> the checksum of the archive that was actually uploaded
#
# Usage: set-binary-targets.sh <base-url> <checksums-file>
#
# <checksums-file> is the "<sha256>  <Name>.xcframework.zip" listing produced by
# swift/Scripts/package-vlc-frameworks.sh.

set -euo pipefail

base_url="${1:?usage: set-binary-targets.sh <base-url> <checksums-file>}"
checksums_file="${2:?usage: set-binary-targets.sh <base-url> <checksums-file>}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
manifest="$REPO_ROOT/Package.swift"

if [[ ! -f "$checksums_file" ]]; then
  echo "error: checksums file not found: $checksums_file" >&2
  exit 1
fi

[[ "$base_url" == */ ]] || base_url="$base_url/"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

awk -v base_url="$base_url" -v checksums_file="$checksums_file" '
  BEGIN {
    while ((getline line < checksums_file) > 0) {
      n = split(line, parts, /[[:space:]]+/)
      if (n < 2) continue
      name = parts[2]
      sub(/\.xcframework\.zip$/, "", name)
      sums[name] = parts[1]
    }
  }

  /^let binaryBaseURL = / {
    print "let binaryBaseURL = \"" base_url "\""
    replaced_url = 1
    next
  }

  match($0, /name: "[A-Za-z]+"/) {
    candidate = substr($0, RSTART + 7, RLENGTH - 8)
    current = (candidate in sums) ? candidate : ""
  }

  current != "" && /checksum: "/ {
    sub(/"[0-9a-fA-F]*"/, "\"" sums[current] "\"")
    replaced[current] = 1
    current = ""
  }

  { print }

  END {
    if (!replaced_url) {
      print "error: binaryBaseURL declaration not found in Package.swift" > "/dev/stderr"
      exit 1
    }
    for (name in sums) {
      if (!(name in replaced)) {
        print "error: no binaryTarget named " name " in Package.swift" > "/dev/stderr"
        exit 1
      }
    }
  }
' "$manifest" > "$tmp"

mv "$tmp" "$manifest"
trap - EXIT

echo "Updated $manifest:"
swift package --package-path "$REPO_ROOT" dump-package \
  | jq -r '.targets[] | select(.type == "binary") | "  \(.name)\n    url:      \(.url)\n    checksum: \(.checksum)"'

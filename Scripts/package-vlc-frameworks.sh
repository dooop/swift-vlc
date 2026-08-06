#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: package-vlc-frameworks.sh [options] [config-file]

Produces the release assets referenced by the binaryTarget declarations in
Package.swift: one `<framework>.xcframework.zip` per entry in the config file,
plus the SwiftPM checksum of each archive.

Steps:
  1. downloads/installs the xcframeworks via Scripts/update-vlc-frameworks.sh
     (skipped with --no-download if Frameworks/ is already populated)
  2. zips each bundle into DIST_DIR
  3. computes the SwiftPM checksum of each zip and writes DIST_DIR/checksums.txt

Options:
  --no-download   Reuse the bundles already present in FRAMEWORKS_DIR
  --verify        Additionally compare the checksums against Package.swift and
                  fail if they differ
  -h, --help      Show this help

Environment overrides:
  FRAMEWORKS_DIR  Source/destination folder for *.xcframework (default: ./Frameworks)
  DIST_DIR        Output folder for the archives (default: ./dist)
EOF
}

download=1
verify=0
config_file=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-download)
      download=0
      shift
      ;;
    --verify)
      verify=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    -*)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      config_file="$1"
      shift
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${config_file:-$SCRIPT_DIR/vlc-frameworks.conf}"
FRAMEWORKS_DIR="${FRAMEWORKS_DIR:-$REPO_ROOT/Frameworks}"
DIST_DIR="${DIST_DIR:-$REPO_ROOT/dist}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

for tool in ditto swift; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool not found: $tool" >&2
    exit 1
  fi
done

manifest_json=""
if [[ "$verify" -eq 1 ]]; then
  if ! command -v jq >/dev/null 2>&1; then
    echo "error: --verify requires jq" >&2
    exit 1
  fi
  manifest_json="$(swift package --package-path "$REPO_ROOT" dump-package)"
fi

if [[ "$download" -eq 1 ]]; then
  echo "==> Downloading xcframeworks"
  FRAMEWORKS_DIR="$FRAMEWORKS_DIR" "$SCRIPT_DIR/update-vlc-frameworks.sh" "$CONFIG_FILE"
fi

mkdir -p "$DIST_DIR"
checksum_file="$DIST_DIR/checksums.txt"
: > "$checksum_file"

exit_code=0

while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"
  if [[ -z "$trimmed" || "${trimmed:0:1}" == "#" ]]; then
    continue
  fi

  IFS='|' read -r framework_name _ _ <<< "$trimmed"
  framework_name="${framework_name//[[:space:]]/}"

  bundle="$FRAMEWORKS_DIR/${framework_name}.xcframework"
  if [[ ! -d "$bundle" ]]; then
    echo "error: missing bundle: $bundle (drop --no-download to fetch it)" >&2
    exit 1
  fi

  archive="$DIST_DIR/${framework_name}.xcframework.zip"

  echo
  echo "==> ${framework_name}"
  echo "Archiving: $archive"
  rm -f "$archive"
  ditto -c -k --sequesterRsrc --keepParent "$bundle" "$archive"

  checksum="$(swift package --package-path "$REPO_ROOT" compute-checksum "$archive")"
  echo "Checksum: $checksum"
  printf '%s %s\n' "$checksum" "${framework_name}.xcframework.zip" >> "$checksum_file"

  if [[ "$verify" -eq 1 ]]; then
    declared="$(
      printf '%s' "$manifest_json" \
        | jq -r --arg name "$framework_name" '
            .targets[] | select(.type == "binary" and .name == $name) | .checksum // empty
          '
    )"

    if [[ "$declared" != "$checksum" ]]; then
      echo "error: checksum mismatch for ${framework_name}" >&2
      echo "  Package.swift: ${declared:-<none>}" >&2
      echo "  archive:       $checksum" >&2
      exit_code=1
    else
      echo "Verified against Package.swift"
    fi
  fi
done < "$CONFIG_FILE"

echo
echo "Archives written to: $DIST_DIR"
cat "$checksum_file"

exit "$exit_code"

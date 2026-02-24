#!/usr/bin/env bash

set -euo pipefail

shopt -s extglob

usage() {
  cat <<'EOF'
Usage: update-vlc-frameworks.sh [config-file]

Downloads VLCKit xcframework archives listed in the config file, extracts and
installs them into the repository Frameworks/ directory, then writes the
archive SHA-256 checksums back into the config file.

Config format (one entry per line):
  <framework-name>|<archive-url>|<sha256>

Environment overrides:
  FRAMEWORKS_DIR   Destination folder for *.xcframework bundles
EOF
}

trim() {
  local value="$1"
  value="${value##+([[:space:]])}"
  value="${value%%+([[:space:]])}"
  printf '%s' "$value"
}

require_tool() {
  local tool="$1"
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool not found: $tool" >&2
    exit 1
  fi
}

extract_archive() {
  local archive="$1"
  local output_dir="$2"

  mkdir -p "$output_dir"

  if tar -xf "$archive" -C "$output_dir" >/dev/null 2>&1; then
    return 0
  fi

  tar -xJf "$archive" -C "$output_dir"
}

find_framework_bundle() {
  local root="$1"
  local framework_name="$2"

  local exact_path
  exact_path="$(find "$root" -type d -name "${framework_name}.xcframework" -print -quit)"
  if [[ -n "$exact_path" ]]; then
    printf '%s' "$exact_path"
    return 0
  fi

  local matches=()
  while IFS= read -r match; do
    matches+=("$match")
  done < <(find "$root" -type d -name '*.xcframework' -print)

  if [[ "${#matches[@]}" -eq 1 ]]; then
    printf '%s' "${matches[0]}"
    return 0
  fi

  if [[ "${#matches[@]}" -eq 0 ]]; then
    echo "error: no .xcframework found in extracted archive for ${framework_name}" >&2
  else
    echo "error: multiple .xcframework bundles found in extracted archive for ${framework_name}" >&2
    printf '  %s\n' "${matches[@]}" >&2
  fi
  return 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_FILE="${1:-$SCRIPT_DIR/vlc-frameworks.conf}"
FRAMEWORKS_DIR="${FRAMEWORKS_DIR:-$REPO_ROOT/Frameworks}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "error: config file not found: $CONFIG_FILE" >&2
  exit 1
fi

require_tool curl
require_tool tar
require_tool shasum
require_tool find
require_tool ditto

mkdir -p "$FRAMEWORKS_DIR"

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/vlc-frameworks.XXXXXX")"
tmp_config="${tmp_dir}/$(basename "$CONFIG_FILE").new"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

echo "Using config: $CONFIG_FILE"
echo "Installing frameworks to: $FRAMEWORKS_DIR"

while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ -z "$(trim "$line")" || "${line:0:1}" == "#" ]]; then
    printf '%s\n' "$line" >> "$tmp_config"
    continue
  fi

  IFS='|' read -r raw_name raw_url raw_checksum _ <<< "$line"
  framework_name="$(trim "${raw_name:-}")"
  archive_url="$(trim "${raw_url:-}")"

  if [[ -z "$framework_name" || -z "$archive_url" ]]; then
    echo "error: malformed config line: $line" >&2
    exit 1
  fi

  archive_path="${tmp_dir}/${framework_name}.archive"
  extract_dir="${tmp_dir}/extract-${framework_name}"

  echo
  echo "==> ${framework_name}"
  echo "Downloading: ${archive_url}"
  curl --fail --location --show-error --silent "$archive_url" --output "$archive_path"

  checksum="$(shasum -a 256 "$archive_path" | awk '{print $1}')"
  echo "Checksum: ${checksum}"

  rm -rf "$extract_dir"
  extract_archive "$archive_path" "$extract_dir"

  source_bundle="$(find_framework_bundle "$extract_dir" "$framework_name")"
  dest_bundle="${FRAMEWORKS_DIR}/${framework_name}.xcframework"

  echo "Installing: ${dest_bundle}"
  rm -rf "$dest_bundle"
  ditto "$source_bundle" "$dest_bundle"

  printf '%s|%s|%s\n' "$framework_name" "$archive_url" "$checksum" >> "$tmp_config"
done < "$CONFIG_FILE"

mv "$tmp_config" "$CONFIG_FILE"

echo
echo "Done. Updated checksums in: $CONFIG_FILE"

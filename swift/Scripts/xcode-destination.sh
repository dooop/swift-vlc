#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: xcode-destination.sh <platform> [kind]

Prints an xcodebuild -destination value for one of the platforms this package
supports. Simulator destinations are resolved to a concrete device UDID from
the newest installed runtime, so no simulator name has to be hard-coded (device
names differ between Xcode versions and CI runner images).

Arguments:
  platform   macos | ios | tvos
  kind       run (default) | build

  "run"   -> a destination that can execute tests (macOS / a booted-able simulator)
  "build" -> a generic destination for compile-only builds

Examples:
  xcodebuild test  -scheme vlc-player-Package -destination "$(swift/Scripts/xcode-destination.sh ios)"
  xcodebuild build -scheme vlc-player-Package -destination "$(swift/Scripts/xcode-destination.sh tvos build)"
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

platform="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
kind="${2:-run}"

if [[ -z "$platform" ]]; then
  usage >&2
  exit 1
fi

case "$platform" in
  macos)
    case "$kind" in
      build) printf 'generic/platform=macOS' ;;
      run) printf 'platform=macOS' ;;
      *)
        echo "error: unknown kind: $kind" >&2
        exit 1
        ;;
    esac
    exit 0
    ;;
  ios)
    device_platform="iOS"
    runtime_prefix="com.apple.CoreSimulator.SimRuntime.iOS-"
    preferred_device="iPhone"
    ;;
  tvos)
    device_platform="tvOS"
    runtime_prefix="com.apple.CoreSimulator.SimRuntime.tvOS-"
    preferred_device="Apple TV"
    ;;
  *)
    echo "error: unknown platform: $platform (expected macos, ios or tvos)" >&2
    exit 1
    ;;
esac

if [[ "$kind" == "build" ]]; then
  # Compile-only: build for the physical device slice, no simulator needed.
  printf 'generic/platform=%s' "$device_platform"
  exit 0
fi

if [[ "$kind" != "run" ]]; then
  echo "error: unknown kind: $kind" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: required tool not found: jq" >&2
  exit 1
fi

udid="$(
  xcrun simctl list devices available --json \
    | jq -r --arg prefix "$runtime_prefix" --arg preferred "$preferred_device" '
        .devices
        | to_entries
        | map(select((.key | startswith($prefix)) and (.value | length > 0)))
        | sort_by(.key | ltrimstr($prefix) | split("-") | map(tonumber))
        | last
        | .value as $devices
        | (   ($devices | map(select(.name | startswith($preferred))) | last)
           // ($devices | last)
          )
        | .udid // empty
      '
)"

if [[ -z "$udid" || "$udid" == "null" ]]; then
  echo "error: no available ${device_platform} simulator found." >&2
  echo "hint: install a ${device_platform} runtime, e.g. 'xcodebuild -downloadPlatform ${device_platform}'" >&2
  exit 1
fi

printf 'platform=%s Simulator,id=%s' "$device_platform" "$udid"

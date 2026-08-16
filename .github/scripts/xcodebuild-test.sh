#!/usr/bin/env bash

set -uo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <destination> [result-bundle-path]" >&2
  exit 64
fi

destination=$1
result_bundle=${2:-}
max_attempts=2

xcodebuild \
  build-for-testing \
  -scheme swift-vlc-player-Package \
  -destination "$destination" \
  -derivedDataPath .derivedData \
  -quiet

xctestrun=
while IFS= read -r candidate; do
  if [[ -z "$xctestrun" || "$candidate" -nt "$xctestrun" ]]; then
    xctestrun=$candidate
  fi
done < <(find .derivedData/Build/Products -maxdepth 1 -type f -name '*.xctestrun' -print)

if [[ -z "$xctestrun" ]]; then
  echo "error: build-for-testing did not produce an .xctestrun file" >&2
  exit 1
fi

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  arguments=(
    test-without-building
    -xctestrun "$xctestrun"
    -destination "$destination"
    -quiet
  )

  if [[ -n "$result_bundle" ]]; then
    attempt_result_bundle=$result_bundle
    if ((attempt > 1)); then
      attempt_result_bundle=${result_bundle%.xcresult}-retry-${attempt}.xcresult
    fi
    arguments+=( -resultBundlePath "$attempt_result_bundle" )
  fi

  if xcodebuild "${arguments[@]}"; then
    exit 0
  else
    status=$?
  fi

  # Keep a retry for unrelated simulator-launch aborts. Test launching uses the
  # immutable xctestrun file, so it cannot invalidate SwiftPM's generated scheme.
  if ((status != 134 || attempt == max_attempts)); then
    exit "$status"
  fi

  echo "::warning::xcodebuild aborted internally; retrying the test action"
done

#!/usr/bin/env bash

set -uo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "usage: $0 <destination> [result-bundle-path]" >&2
  exit 64
fi

destination=$1
result_bundle=${2:-}
max_attempts=2

for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  arguments=(
    test
    -scheme swift-vlc-player-Package
    -destination "$destination"
    -derivedDataPath .derivedData
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

  # Xcode 26 can abort while launching Swift-package tests after invalidating
  # its generated package scheme. A new xcodebuild process regenerates it.
  if ((status != 134 || attempt == max_attempts)); then
    exit "$status"
  fi

  echo "::warning::xcodebuild aborted internally; retrying the test action"
done

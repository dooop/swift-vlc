#!/usr/bin/env bash
#
# Selects the Xcode used by every following step and fails early if it is too
# old for this package (Swift 6 tools and reliable Swift Package String Catalog
# symbol generation).
#
# Honours $XCODE_APP if set, otherwise keeps the runner image default.

set -euo pipefail

if [[ -n "${XCODE_APP:-}" ]]; then
  if [[ ! -d "$XCODE_APP" ]]; then
    echo "::error::XCODE_APP does not exist: $XCODE_APP"
    echo "Installed Xcode versions:"
    ls -d /Applications/Xcode*.app 2>/dev/null || true
    exit 1
  fi
  developer_dir="$XCODE_APP/Contents/Developer"
  sudo xcode-select --switch "$developer_dir"
  if [[ -n "${GITHUB_ENV:-}" ]]; then
    echo "DEVELOPER_DIR=$developer_dir" >> "$GITHUB_ENV"
  fi
fi

xcodebuild -version
swift --version

xcode_major="$(xcodebuild -version | sed -n '1s/Xcode \([0-9]*\).*/\1/p')"
if [[ -z "$xcode_major" || "$xcode_major" -lt 26 ]]; then
  echo "::error::Xcode 26 or newer is required (found: $(xcodebuild -version | head -1))."
  exit 1
fi

echo "Available simulator runtimes:"
xcrun simctl list runtimes available

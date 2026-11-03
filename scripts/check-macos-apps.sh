#!/usr/bin/env bash
# Detect incomplete app bundles left behind by interrupted cask upgrades.
set -euo pipefail

status=0
for app in "${1:-/Applications}"/*.app; do
  [[ -d "$app" ]] || continue
  plist="$app/Contents/Info.plist"
  executable=""
  if [[ -f "$plist" ]]; then
    executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist" 2>/dev/null || true)"
  fi
  if [[ -z "$executable" || ! -x "$app/Contents/MacOS/$executable" ]]; then
    echo "Incomplete application bundle: $app" >&2
    status=1
  fi
done

if [[ "$status" != 0 ]]; then
  echo "Reinstall the affected Homebrew casks with 'brew reinstall --cask <cask>', then retry." >&2
  echo "Homebrew may otherwise adopt an empty app directory as an installed application." >&2
fi
exit "$status"

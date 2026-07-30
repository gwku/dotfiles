#!/usr/bin/env bash
# Restore the desired Mac App Store applications after signing into the
# App Store. Kept separate from nix-darwin activation so clean VM tests
# and unattended builds never require Apple ID credentials.

set -euo pipefail

command -v mas >/dev/null 2>&1 || {
  echo "mas is unavailable; activate the nix-darwin configuration first." >&2
  exit 1
}

apps=(
  "937984704:Amphetamine"
  "1474276998:HP Smart"
  "409183694:Keynote"
  "462054704:Microsoft Word"
  "409203825:Numbers"
  "409201541:Pages"
  "585829637:Todoist"
  "1451685025:WireGuard"
)

installed_ids="$(mas list | awk '{ print $1 }')"
for app in "${apps[@]}"; do
  id="${app%%:*}"
  name="${app#*:}"

  if grep -qx "$id" <<<"$installed_ids"; then
    echo "Using ${name}"
    continue
  fi

  echo "Installing ${name}..."
  if ! mas install "$id"; then
    echo "Could not install ${name}. Sign into the App Store and retry." >&2
    exit 1
  fi
done

echo "All desired Mac App Store applications are installed."

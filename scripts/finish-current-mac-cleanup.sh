#!/usr/bin/env bash
# Remove privileged leftovers that Homebrew cannot own or clean up.
#
# Run this once, from Terminal, after the first successful nix-darwin
# switch. The files are moved to the Trash rather than deleted.

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This cleanup is only for macOS." >&2
  exit 1
fi

archive="${HOME}/.Trash/dotfiles-legacy-system-files"
if [[ -e "$archive" ]]; then
  echo "Refusing to overwrite existing archive: $archive" >&2
  echo "Inspect or rename it, then run this script again." >&2
  exit 1
fi

legacy_files=(
  /Library/LaunchDaemons/com.docker.socket.plist
  /Library/LaunchDaemons/com.docker.vmnetd.plist
  /Library/PrivilegedHelperTools/com.docker.socket
  /Library/PrivilegedHelperTools/com.docker.vmnetd
)

found=false
for item in "${legacy_files[@]}"; do
  if [[ -e "$item" ]]; then
    found=true
    break
  fi
done

if $found; then
  mkdir -p "$archive"
  sudo -v
  for item in "${legacy_files[@]}"; do
    if [[ -e "$item" ]]; then
      sudo mv "$item" "$archive/"
      echo "Moved $item"
    fi
  done
  sudo chown -R "$USER":staff "$archive"
  echo "Docker helpers are recoverable from: $archive"
else
  echo "No legacy Docker helpers found."
fi

# Complete any extension uninstall already requested through its owning app.
systemextensionsctl gc

if systemextensionsctl list 2>/dev/null |
  grep -q "waiting to uninstall on reboot"; then
  echo "A system extension is waiting to uninstall. Reboot once to finish."
else
  echo "No system extension is waiting to uninstall."
fi

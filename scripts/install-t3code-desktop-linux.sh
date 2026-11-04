#!/usr/bin/env bash
# Install the official desktop AppImage without changing a headless T3 service.
set -euo pipefail

version=0.1.8-nightly.20261104.4192
artifact="T3-Code-${version}-x86_64.AppImage"
sha256=41cc55da96f08a1c11fca41732028d27fe01caf30206b3fb0cc3d15bd57a714d
directory="$HOME/.local/opt/t3code-nightly"
image="$directory/$artifact"
appdir="$directory/$version.appdir"
client_only=false
case "${1:-}" in
  '') ;;
  --client-only) client_only=true ;;
  --check)
    test -x "$image"
    printf '%s  %s\n' "$sha256" "$image" | sha256sum --check --status
    test -x "$HOME/.local/bin/t3code-desktop"
    test -x "$appdir/AppRun"
    test -f "$HOME/.local/share/applications/t3code-nightly.desktop"
    printf 'Official T3 Code desktop %s installed\n' "$version"
    exit 0 ;;
  -h|--help)
    printf '%s\n' 'Usage: install-t3code-desktop-linux.sh [--client-only|--check]' \
      '--client-only disables the desktop-managed backend before first launch.' \
      'Pair the desktop with the existing headless server and other computers.'
    exit 0 ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { printf 'Expected at most one option\n' >&2; exit 2; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'This installer supports x86_64 Linux only\n' >&2; exit 1;
}
if [[ "$client_only" == true ]]; then
  # The app must be closed before its documented JSON settings are changed.
  if pgrep -u "$(id -u)" -f '/[Tt]3[- ]?[Cc]ode.*AppImage|/t3code.*--type=' >/dev/null; then
    printf 'Close the T3 desktop app before applying --client-only\n' >&2
    exit 1
  fi
fi

mkdir -p "$directory" "$HOME/.local/bin" "$HOME/.local/share/applications"
if [[ ! -f "$image" ]] || ! printf '%s  %s\n' "$sha256" "$image" | sha256sum --check --status; then
  download="$image.download"
  if [[ ! -f "$download" ]] || ! printf '%s  %s\n' "$sha256" "$download" | sha256sum --check --status; then
    curl --fail --location --retry 3 \
      "https://github.com/pingdotgg/t3code/releases/download/v$version/$artifact" \
      --output "$download"
  fi
  printf '%s  %s\n' "$sha256" "$download" | sha256sum --check --status
  chmod 755 "$download"
  mv "$download" "$image"
fi
chmod 755 "$image"

# Extract the official AppImage once. This also avoids broken AppImageLauncher
# binfmt/FUSE interception; Electron's own sandbox remains enabled.
if [[ ! -x "$appdir/AppRun" ]]; then
  command -v unsquashfs >/dev/null || {
    printf 'Install squashfs-tools with pacman before continuing\n' >&2; exit 1;
  }
  offset=$(APPIMAGELAUNCHER_DISABLE=1 "$image" --appimage-offset)
  [[ "$offset" =~ ^[0-9]+$ ]] || { printf 'Invalid AppImage filesystem offset\n' >&2; exit 1; }
  staging=$(mktemp -d "$directory/.extract.XXXXXXXX")
  trap 'rm -rf "$staging"' EXIT
  unsquashfs -processors 4 -no-progress -offset "$offset" \
    -dest "$staging/appdir" "$image" >/dev/null
  mv "$staging/appdir" "$appdir"
  rmdir "$staging"
  trap - EXIT
fi

if [[ "$client_only" == true ]]; then
  python3 - <<'PY'
import json, os, shutil
from pathlib import Path
p = Path.home() / '.t3/userdata/desktop-settings.json'
p.parent.mkdir(parents=True, exist_ok=True)
settings = json.loads(p.read_text()) if p.exists() else {}
if p.exists() and settings.get('localEnvironmentEnabled') is not False:
    backup = p.with_name('desktop-settings.before-client-only.json')
    if not backup.exists():
        shutil.copy2(p, backup)
settings['localEnvironmentEnabled'] = False
settings['updateChannel'] = 'nightly'
temporary = p.with_suffix('.json.new')
temporary.write_text(json.dumps(settings, indent=2) + '\n')
os.chmod(temporary, 0o600)
temporary.replace(p)
PY
fi

printf '#!/usr/bin/env bash\nexport T3CODE_HOME="$HOME/.t3"\nexec %q "$@"\n' "$appdir/AppRun" \
  > "$HOME/.local/bin/t3code-desktop"
chmod 755 "$HOME/.local/bin/t3code-desktop"
cat > "$HOME/.local/share/applications/t3code-nightly.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=T3 Code (Nightly)
Comment=T3 Code desktop client
Exec=$HOME/.local/bin/t3code-desktop %U
Icon=applications-development
Terminal=false
Categories=Development;IDE;
MimeType=x-scheme-handler/t3code;x-scheme-handler/t3code-nightly;
EOF
update-desktop-database "$HOME/.local/share/applications"
xdg-mime default t3code-nightly.desktop x-scheme-handler/t3code
xdg-mime default t3code-nightly.desktop x-scheme-handler/t3code-nightly
printf 'Installed T3 Code desktop %s; launch t3code-desktop\n' "$version"
if [[ "$client_only" == true ]]; then
  printf 'Desktop backend disabled; existing headless service is unchanged\n'
fi

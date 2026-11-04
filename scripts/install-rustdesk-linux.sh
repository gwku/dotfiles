#!/usr/bin/env bash
# Native Arch/CachyOS installation without the vendor's automatic service start.
set -euo pipefail

version=1.5.1-0
artifact=rustdesk-1.5.1-0-x86_64.pkg.tar.zst
url="https://github.com/rustdesk/rustdesk/releases/download/1.5.1/$artifact"
sha256=b1dcad4d23ac91b6ce662a2a1495d69a92b5b1ae5d7b6c5b0e11a6cbfc9cccac
mode=install
case "${1:-}" in
  '') ;;
  --check) mode=check ;;
  --reinstall) mode=reinstall ;;
  -h|--help)
    printf '%s\n' 'Usage: install-rustdesk-linux.sh [--check|--reinstall]' \
      'Install the verified official Arch package; preserve local config and service state.' \
      '--check reports package/integration state without changes.' \
      '--reinstall reapplies the pinned version, but never downgrades a newer package.'
    exit 0 ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { printf 'Expected at most one option\n' >&2; exit 2; }
[[ $(uname -s) == Linux && $(uname -m) == x86_64 ]] || {
  printf 'This installer supports x86_64 Arch/CachyOS Linux only\n' >&2; exit 1;
}
for tool in pacman vercmp cmp; do
  command -v "$tool" >/dev/null || { printf 'Missing command: %s\n' "$tool" >&2; exit 1; }
done

installed=$(pacman -Q rustdesk 2>/dev/null | awk '{print $2}') || installed=
comparison=-1
if [[ -n "$installed" ]]; then comparison=$(vercmp "$installed" "$version"); fi
sources=(
  /usr/share/rustdesk/files/rustdesk.service
  /usr/share/rustdesk/files/rustdesk.desktop
  /usr/share/rustdesk/files/rustdesk-link.desktop
)
targets=(
  /etc/systemd/system/rustdesk.service
  /usr/share/applications/rustdesk.desktop
  /usr/share/applications/rustdesk-link.desktop
)
integration_ok=true
for index in "${!sources[@]}"; do
  if ! cmp -s "${sources[$index]}" "${targets[$index]}"; then integration_ok=false; fi
done
if [[ "$mode" == check ]]; then
  printf 'Installed RustDesk: %s (reference %s)\n' "${installed:-absent}" "$version"
  printf 'Vendor service/desktop integration matches: %s\n' "$integration_ok"
  [[ "$comparison" -ge 0 && "$integration_ok" == true ]]
  exit
fi
if [[ "$comparison" -ge 0 && "$integration_ok" == true && "$mode" != reinstall ]]; then
  printf 'RustDesk %s and desktop/service files already present; no changes\n' "$installed"
  exit 0
fi

privilege=()
if [[ $EUID -ne 0 ]]; then privilege=(sudo); fi
if [[ "$comparison" -lt 0 || ("$mode" == reinstall && "$comparison" -eq 0) ]]; then
  for tool in curl sha256sum bsdtar; do
    command -v "$tool" >/dev/null || { printf 'Missing command: %s\n' "$tool" >&2; exit 1; }
  done
  workspace=$(mktemp -d -t rustdesk-install.XXXXXXXX)
  trap 'rm -rf -- "$workspace"' EXIT
  package="$workspace/$artifact"
  curl --fail --location --proto '=https' --proto-redir '=https' --tlsv1.2 \
    --retry 3 --output "$package" "$url"
  if ! printf '%s  %s\n' "$sha256" "$package" | sha256sum --check --status; then
    printf 'RustDesk package checksum mismatch; refusing installation\n' >&2; exit 1
  fi
  metadata=$(bsdtar -xOf "$package" .PKGINFO)
  for entry in 'pkgname = rustdesk' "pkgver = $version" 'arch = x86_64'; do
    if ! printf '%s\n' "$metadata" | grep -Fxq "$entry"; then
      printf 'Unexpected package metadata; refusing installation\n' >&2; exit 1
    fi
  done
  # Vendor post_install/post_upgrade would enable/start RustDesk against default
  # servers. Suppress scriptlets; reproduce only service/launcher installation.
  "${privilege[@]}" pacman -U --noscriptlet "$package"
elif [[ "$comparison" -gt 0 ]]; then
  printf 'Keeping newer RustDesk %s; repairing integration only if needed\n' "$installed"
fi

for index in "${!sources[@]}"; do
  if [[ ! -e "${targets[$index]}" ]]; then
    "${privilege[@]}" install -D -m 0644 "${sources[$index]}" "${targets[$index]}"
  elif ! cmp -s "${sources[$index]}" "${targets[$index]}"; then
    printf 'Preserving existing customized integration file: %s\n' "${targets[$index]}"
  fi
done
"${privilege[@]}" systemctl daemon-reload
if command -v update-desktop-database >/dev/null; then
  "${privilege[@]}" update-desktop-database /usr/share/applications
fi
printf '%s\n' 'RustDesk installed. Existing identities, settings, and service state preserved.' \
  'Configure the private server/click policy before explicitly starting attended sharing.'

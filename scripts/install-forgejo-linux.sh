#!/usr/bin/env bash
# Native Arch/CachyOS installation from signed repositories.
set -euo pipefail

case "${1:-}" in
  '') mode=install ;;
  --check) mode=check ;;
  -h|--help)
    printf '%s\n' 'Usage: install-forgejo-linux.sh [--check]' \
      'Install fj >= 0.6 from the configured Arch/CachyOS repositories.'
    exit 0 ;;
  *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
esac
[[ $# -le 1 ]] || { printf 'Expected at most one option\n' >&2; exit 2; }
[[ $(uname -s) == Linux ]] && command -v pacman >/dev/null || {
  printf 'This installer requires Arch/CachyOS Linux\n' >&2; exit 1;
}

compatible() {
  command -v fj >/dev/null || return 1
  local version
  version=$(fj version | sed -n 's/^fj v\([0-9][^ ]*\).*/\1/p')
  [[ -n "$version" && $(vercmp "$version" 0.6.0) -ge 0 ]]
}
if compatible; then fj version; exit 0; fi
if [[ "$mode" == check ]]; then
  printf 'Missing compatible fj; version >= 0.6 is required\n' >&2
  exit 1
fi

# Do not refresh package databases or create a partial system upgrade.
if [[ $(id -u) == 0 ]]; then
  pacman -S --needed forgejo-cli
else
  sudo pacman -S --needed forgejo-cli
fi
compatible || { printf 'Installed fj is too old for T3 Code\n' >&2; exit 1; }
fj version

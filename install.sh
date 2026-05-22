#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
  echo "usage: ./install.sh <hostname>" >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  # Official upstream Nix installer. Avoid the Determinate Systems
  # installer here — as of 2026 it ships Determinate Nix (a fork) and
  # doesn't play well with nix-darwin.
  echo "Installing upstream Nix..."
  sh <(curl -L https://nixos.org/nix/install) --daemon
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

case "$(uname -s)" in
  Darwin)
    echo "Applying nix-darwin configuration for host: ${HOST}"
    sudo nix run --extra-experimental-features 'nix-command flakes' \
      nix-darwin -- switch --flake ".#${HOST}"
    ;;
  Linux)
    echo "Applying standalone Home Manager configuration for host: ${HOST}"
    nix run --extra-experimental-features 'nix-command flakes' \
      home-manager/master -- switch --flake ".#${USER}@${HOST}"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac

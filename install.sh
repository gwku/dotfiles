#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
  echo "usage: ./install.sh <hostname>" >&2
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Nix via the Determinate Systems installer..."
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
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
      home-manager/master -- switch --flake ".#gwku@${HOST}"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac

#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-}"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "$HOST" ]]; then
  echo "usage: ./install.sh <hostname>" >&2
  exit 1
fi
cd "$REPO_ROOT"
FLAKE_REF="path:${REPO_ROOT}"

if ! command -v nix >/dev/null 2>&1; then
  echo "Installing Determinate Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L \
    https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

case "$(uname -s)" in
  Darwin)
    EXPECTED_USER="$(nix --extra-experimental-features 'nix-command flakes' \
      eval --raw "${FLAKE_REF}#darwinConfigurations.${HOST}.config.system.primaryUser")"
    if ! id "$EXPECTED_USER" >/dev/null 2>&1; then
      echo "Configured macOS user '${EXPECTED_USER}' does not exist." >&2
      echo "Create/use that short account name before bootstrapping." >&2
      exit 1
    fi
    if [[ "$USER" != "$EXPECTED_USER" ]]; then
      echo "Run this installer while logged in as '${EXPECTED_USER}', not '${USER}'." >&2
      exit 1
    fi

    echo "Applying nix-darwin configuration for host: ${HOST}"
    sudo nix run --extra-experimental-features 'nix-command flakes' \
      "${FLAKE_REF}#darwin-rebuild" -- switch --flake "${FLAKE_REF}#${HOST}"
    ;;
  Linux)
    echo "Applying standalone Home Manager configuration for host: ${HOST}"
    nix run --extra-experimental-features 'nix-command flakes' \
      "${FLAKE_REF}#home-manager" -- switch --flake "${FLAKE_REF}#${USER}@${HOST}"
    ;;
  *)
    echo "Unsupported platform: $(uname -s)" >&2
    exit 1
    ;;
esac

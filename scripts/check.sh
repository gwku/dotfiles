#!/usr/bin/env bash
# Build the nix-darwin configuration without activating it.
# Catches eval errors, missing packages, schema mismatches — without
# touching the running system.
#
# Usage:  ./scripts/check.sh [hostname]
# Default hostname: gkmp.

set -euo pipefail

HOST="${1:-gkmp}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 1. Ensure Nix is installed.
if ! command -v nix >/dev/null 2>&1; then
  echo "Nix not found. Install with:"
  echo "  sh <(curl -L https://nixos.org/nix/install) --daemon"
  echo
  echo "(Use upstream Nix, NOT the Determinate Systems installer —"
  echo " Determinate Nix doesn't play well with nix-darwin as of 2026.)"
  exit 1
fi

cd "$REPO_ROOT"

NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

# 2. Evaluate the flake — fast, no builds.
echo "==> nix flake check"
nix "${NIX_FLAGS[@]}" flake check --no-build || {
  echo "Flake check failed. Fix evaluation errors before going further."
  exit 1
}

# 3. Build the full darwin system (no switch).
echo
echo "==> darwin-rebuild build --flake .#${HOST}"
nix "${NIX_FLAGS[@]}" run nix-darwin -- build --flake ".#${HOST}"

echo
echo "Build succeeded. To activate, run:"
echo "  sudo nix run nix-darwin -- switch --flake .#${HOST}"

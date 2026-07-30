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
  echo "  curl --proto '=https' --tlsv1.2 -sSf -L \\"
  echo "    https://install.determinate.systems/nix | sh -s -- install"
  echo
  echo "This repository is configured for Determinate Nix."
  exit 1
fi

cd "$REPO_ROOT"

NIX_FLAGS=(--extra-experimental-features 'nix-command flakes')

# 2. Evaluate the flake — fast, no builds.
echo "==> nix flake check --all-systems"
nix "${NIX_FLAGS[@]}" flake check path:. --all-systems --no-build || {
  echo "Flake check failed. Fix evaluation errors before going further."
  exit 1
}

# 3. Build the full darwin system (no switch).
echo
echo "==> nix build path:.#darwinConfigurations.${HOST}.system"
nix "${NIX_FLAGS[@]}" build --no-link "path:.#darwinConfigurations.${HOST}.system"

echo
echo "Build succeeded. To activate, run:"
echo "  sudo nix run path:.#darwin-rebuild -- switch --flake path:.#${HOST}"

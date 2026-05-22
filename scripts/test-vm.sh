#!/usr/bin/env bash
# Spin up a macOS VM via tart and mount this repo inside it, so the
# dotfiles can be tested without touching the host system.
#
# Usage:    ./scripts/test-vm.sh
# Env vars: TART_IMAGE  — OCI image to clone (default: macos-tahoe-base:latest)
#          VM_NAME     — local VM name (default: dotfiles-test)
#          HOST_NAME   — flake host to build inside the VM (default: gkmp)

set -euo pipefail

# Default to Tahoe (macOS 26) so the VM matches the host OS version.
IMAGE="${TART_IMAGE:-ghcr.io/cirruslabs/macos-tahoe-base:latest}"
VM_NAME="${VM_NAME:-dotfiles-test}"
HOST_NAME="${HOST_NAME:-gkmp}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v tart >/dev/null 2>&1; then
  cat >&2 <<EOF
tart is not installed. Bootstrap it:

  brew install cirruslabs/cli/tart

It will also be declared in modules/darwin/homebrew.nix on next switch.
EOF
  exit 1
fi

# Clone the OCI image into a local VM if missing. First run pulls
# ~30-40 GB; subsequent runs reuse the same VM.
if ! tart list --format json 2>/dev/null | grep -q "\"Name\":\"${VM_NAME}\""; then
  echo "==> No local VM '${VM_NAME}' — cloning from ${IMAGE}"
  echo "    First-time download: ~30-40 GB. Subsequent runs are instant."
  tart clone "$IMAGE" "$VM_NAME"
fi

cat <<EOF
==> Starting VM '${VM_NAME}' with the dotfiles repo mounted.

    The repo lives at:  /Volumes/My Shared Files/dotfiles
    Login credentials:  admin / admin
    Network:            \$(tart ip ${VM_NAME} 2>/dev/null || echo "<assigned on boot>")

    Once macOS finishes booting, open Terminal inside the VM and run:

      cd '/Volumes/My Shared Files/dotfiles'
      sh <(curl -L https://nixos.org/nix/install) --daemon
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      ./scripts/check.sh ${HOST_NAME}

    Optional (full switch test, applies the config inside the VM):

      sudo nix run nix-darwin -- switch --flake .#${HOST_NAME}

    To SSH from another terminal on the host:

      ssh admin@\$(tart ip ${VM_NAME})

    To shut down: Ctrl-C in this window, or 'tart stop ${VM_NAME}' elsewhere.
    To delete the VM later (frees ~30 GB): tart delete ${VM_NAME}

EOF

# Foreground GUI run so the user can see boot progress + interact.
tart run "$VM_NAME" --dir=dotfiles:"$REPO_ROOT"

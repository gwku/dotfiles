{ lib, pkgs, ... }:
{
  imports = [ ./tunnels.nix ./private-sync.nix ];
  # Merge only reviewed portable keys into writable config. T3 owns credentials,
  # provider/device configuration, onboarding, runtime state, and databases.
  home.activation.installT3CodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    private_mode=()
    private_state="''${XDG_STATE_HOME:-$HOME/.local/state}/t3-portable-sync"
    if [[ -f "$private_state/payload.json" || -f "$private_state/receipt.json" ]]; then
      private_mode=(--defaults-only)
    fi
    run ${pkgs.python3}/bin/python3 ${./sync-portable-settings.py} \
      --source ${./.} --destination "$HOME/.t3/userdata" \
      --platform ${pkgs.stdenv.hostPlatform.system} "''${private_mode[@]}"
  '';
}

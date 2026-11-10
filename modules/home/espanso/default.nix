{ config, lib, pkgs, ... }:
let
  source = "${config.home.homeDirectory}/development/dotfiles/modules/home/espanso/files";
  emoji = pkgs.callPackage ../../../packages/espanso-all-emojis { };
  setup = pkgs.writeShellScriptBin "espanso-setup" ''
    exec ${pkgs.python3}/bin/python3 ${../../../scripts/setup-espanso.py} \
      --source ${lib.escapeShellArg source} --emoji-package ${emoji} "$@"
  '';
in
{
  home.packages = [ setup ];

  # Public files are first-run defaults only. All user edits live in a
  # private runtime outside this checkout and outside the readable Nix store.
  home.activation.linkEspanso = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setup}/bin/espanso-setup
  '';

  # Use Homebrew's stable signed app path for macOS Accessibility approval.
  # Register the official service for menu-bar and CLI start/stop controls.
  home.activation.registerEspanso = lib.mkIf pkgs.stdenv.isDarwin (
    lib.hm.dag.entryAfter [ "linkEspanso" ] ''
      if [ -x /opt/homebrew/bin/espanso ]; then
        # launchd remembers disabled agents even after their plist is replaced.
        # Clear that state before the upstream registrar attempts to load it.
        domain="gui/$(id -u)"
        if /bin/launchctl print "$domain" >/dev/null 2>&1; then
          run /bin/launchctl enable "$domain/com.federicoterzi.espanso"
          if ! /opt/homebrew/bin/espanso service check >/dev/null 2>&1; then
            run /opt/homebrew/bin/espanso service register
          fi
          if ! /bin/launchctl print "$domain/com.federicoterzi.espanso" >/dev/null 2>&1; then
            run /bin/launchctl bootstrap "$domain" "$HOME/Library/LaunchAgents/com.federicoterzi.espanso.plist"
          fi
        else
          echo "Espanso: no graphical login session; open Espanso once after login to finish startup registration." >&2
        fi
      else
        echo "Espanso: open the Homebrew app once after installation to register login startup." >&2
      fi
    ''
  );

  # Let the upstream HM module choose the X11/Wayland binary. Empty file maps
  # prevent it from generating any read-only configuration alongside our link.
  services.espanso = lib.mkIf pkgs.stdenv.isLinux {
    enable = true;
    configs = { };
    matches = { };
  };
  systemd.user.services.espanso = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };
}

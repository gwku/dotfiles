{ lib, pkgs, ... }:
let
  sync = pkgs.writeShellApplication {
    name = "t3-private-sync";
    runtimeInputs = [ pkgs.python3 pkgs.openssh ];
    text = ''exec python3 ${./private-sync.py} "$@"'';
  };
in
{
  home.packages = [ sync ];
  launchd.agents.t3-private-sync = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${sync}/bin/t3-private-sync" ];
      RunAtLoad = true;
      StartInterval = 30;
      ProcessType = "Background";
    };
  };
  systemd.user.services.t3-private-sync = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Private portable T3 preferences";
    Service = { Type = "oneshot"; ExecStart = "${sync}/bin/t3-private-sync"; };
  };
  systemd.user.timers.t3-private-sync = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Refresh private portable T3 preferences";
    Timer = { OnBootSec = 30; OnUnitActiveSec = 30; };
    Install.WantedBy = [ "timers.target" ];
  };
}

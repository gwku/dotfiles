{ lib, pkgs, ... }:
let
  tunnel = pkgs.writeShellApplication {
    name = "t3-ssh-tunnel";
    runtimeInputs = with pkgs; [ openssh python3 tailscale ];
    text = builtins.readFile ../../../scripts/t3-ssh-tunnel.sh;
  };
in
{
  home.packages = [ tunnel pkgs.tailscale ];
  # Peer inventory is private runtime data, never a Nix-store input.
  launchd.agents.t3-tunnels = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${tunnel}/bin/t3-ssh-tunnel" ];
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ProcessType = "Background";
    };
  };
  systemd.user.services.t3-tunnels = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "Private T3 loopback forwards";
    Service = {
      ExecStart = "${tunnel}/bin/t3-ssh-tunnel";
      Restart = "on-failure";
      RestartSec = 30;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

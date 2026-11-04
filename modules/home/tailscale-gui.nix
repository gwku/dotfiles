{ lib, pkgs, ... }:
let
  menu = pkgs.callPackage ../../packages/tailscale-systray { };
in
{
  # These front ends control the existing tailscaled socket. They do not create
  # a second VPN backend, re-enroll a node, or replace local daemon state.
  home.packages = lib.optionals pkgs.stdenv.isDarwin [ menu ]
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.tailscale ];

  launchd.agents.tailscale-menu = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${menu}/Applications/Tailscale Menu.app/Contents/MacOS/tailscale-menu"
        "-socket"
        "/var/run/tailscaled.socket"
      ];
      RunAtLoad = true;
      KeepAlive = false;
      ProcessType = "Interactive";
    };
  };

  systemd.user.services.tailscale-systray = lib.mkIf pkgs.stdenv.isLinux {
    Unit = {
      Description = "Tailscale system tray controller";
      After = [ "graphical-session.target" "dbus.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.tailscale}/bin/tailscale systray";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

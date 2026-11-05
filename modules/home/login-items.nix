{ lib, pkgs, ... }:
let
  loginItems = {
    bitwarden = "/Applications/Bitwarden.app";
    elgato-wave-link = "/Applications/Elgato Wave Link.app";
    ice = "/Applications/Ice.app";
    itsycal = "/Applications/Itsycal.app";
    maccy = "/Applications/Maccy.app";
    nextcloud = "/Applications/Nextcloud.app";
    scroll-reverser = "/Applications/Scroll Reverser.app";
    t3-code = "/Applications/T3 Code (Nightly).app";
    rustdesk = "/Applications/RustDesk.app";
  };
in
lib.mkIf pkgs.stdenv.isDarwin {
  # LaunchAgents provide reproducible login startup without mutating macOS's
  # opaque, per-user Login Items database. `open` is idempotent when an app is
  # already running, and -g keeps these menu-bar/background apps in the back.
  launchd.agents = (lib.mapAttrs (_: appPath: {
    enable = true;
    config = {
      ProgramArguments = [
        "/usr/bin/open"
        "-g"
        appPath
      ];
      ProcessType = "Interactive";
      RunAtLoad = true;
    };
  }) loginItems) // {
    # -s inhibits system sleep only on AC power. Displays may still sleep,
    # and unplugging restores normal battery sleep without a settings change.
    t3-ac-awake = {
      enable = true;
      config = {
        ProgramArguments = [ "/usr/bin/caffeinate" "-s" ];
        ProcessType = "Background";
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}

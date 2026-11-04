{ pkgs, ... }:
{
  networking.applicationFirewall.enable = true;
  networking.applicationFirewall.allowSigned = true;
  networking.applicationFirewall.allowSignedApp = true;

  system.activationScripts.postActivation.text = ''
    for executable in \
      ${pkgs.tailscale}/bin/tailscaled \
      ${pkgs.tailscale}/bin/.tailscaled-wrapped \
      "/Applications/T3 Code (Nightly).app/Contents/MacOS/T3 Code (Nightly)" \
      /usr/libexec/sshd-auth /usr/libexec/sshd-keygen-wrapper; do
      if [ -x "$executable" ]; then
        /usr/libexec/ApplicationFirewall/socketfilterfw --add "$executable"
        /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$executable"
      fi
    done
  '';

  launchd.daemons.t3-mesh-firewall = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${../../scripts/t3-mesh-firewall.py}"
        "--tailscale" "${pkgs.tailscale}/bin/tailscale"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      ProcessType = "Background";
      StandardErrorPath = "/var/log/t3-mesh-firewall.log";
    };
  };
}

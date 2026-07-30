{
  config,
  lib,
  pkgs,
  ...
}:
let
  bitwardenAgentSocket = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

  syncSshFromBitwarden = pkgs.writeShellApplication {
    name = "bw-ssh-sync";
    runtimeInputs = with pkgs; [
      bitwarden-cli
      coreutils
      findutils
      gawk
      gnugrep
      jq
      openssh
    ];
    text = builtins.readFile ../../scripts/sync-ssh-from-bitwarden.sh;
  };
in
{
  home.packages = [ syncSshFromBitwarden ];

  # The Bitwarden desktop agent holds every private key. This also makes the
  # socket visible to tools such as ssh-add; OpenSSH itself uses IdentityAgent
  # below, so it does not depend on shell environment propagation.
  home.sessionVariables.SSH_AUTH_SOCK = bitwardenAgentSocket;

  # Interactive unlock happens in scripts/switch.sh before the build starts.
  # Activation itself never blocks a long rebuild on a late password prompt.
  home.activation.syncSshFromBitwarden = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${syncSshFromBitwarden}/bin/bw-ssh-sync --non-interactive
  '';

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Private host data is generated from Bitwarden item metadata.
    includes = [
      "~/.orbstack/ssh/config"
      "~/.ssh/config.bitwarden"
    ];

    settings = {
      "*" = {
        IdentityAgent = bitwardenAgentSocket;
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };

      "*.local" = {
        ForwardAgent = false;
        CheckHostIP = false;
      };
    };
  };
}

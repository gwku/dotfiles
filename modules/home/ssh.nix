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

  # During an interactive rebuild, prompt to unlock an already logged-in CLI.
  # A clean machine where `bw login` has never run still skips without failing.
  home.activation.syncSshFromBitwarden = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${syncSshFromBitwarden}/bin/bw-ssh-sync --activation
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
      }
      // lib.optionalAttrs pkgs.stdenv.isDarwin {
        UseKeychain = "yes";
      };

      "*.local" = {
        ForwardAgent = false;
        CheckHostIP = false;
      };
    };
  };
}

{ lib, pkgs, ... }: {
  # Writes ~/.ssh/config only. Keys are placed in ~/.ssh/ manually,
  # never via Nix and never committed.
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        UseKeychain = "yes";
      };

      "github.com" = {
        Hostname = "github.com";
        User = "git";
        IdentitiesOnly = true;
        IdentityFile = "~/.ssh/id_ed25519";
      };

      "*.local" = {
        ForwardAgent = false;
        CheckHostIP = false;
      };
    };
  };
}

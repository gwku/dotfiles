{ lib, pkgs, ... }: {
  # Writes ~/.ssh/config only. Keys are placed in ~/.ssh/ manually,
  # never via Nix and never committed.
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";

    extraConfig = ''
      ServerAliveInterval 60
      ServerAliveCountMax 3
    '' + lib.optionalString pkgs.stdenv.isDarwin ''
      UseKeychain yes
      AddKeysToAgent yes
    '';

    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = [ "~/.ssh/id_ed25519" ];
      };

      "*.local" = {
        forwardAgent = false;
        checkHostIP = false;
      };
    };
  };
}

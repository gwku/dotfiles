{ pkgs, username, ... }: {
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "@admin" username ];
  };

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    interval.Day = 7;
    options = "--delete-older-than 14d";
  };

  nixpkgs.config.allowUnfree = true;

  # Fish at the system level so it's a valid login shell.
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.users.${username}.shell = pkgs.fish;
}

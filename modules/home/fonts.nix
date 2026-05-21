{ pkgs, lib, ... }: {
  # On Darwin, fonts are installed system-wide via nix-darwin (see
  # modules/darwin/fonts.nix). On Linux, install them at the user level
  # so fontconfig picks them up.
  home.packages = lib.optionals pkgs.stdenv.isLinux [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  fonts.fontconfig.enable = lib.mkIf pkgs.stdenv.isLinux true;
}

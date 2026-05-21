{ pkgs, ... }: {
  # JDK 11 and 17 side-by-side. Zulu 21 is provided via cask
  # (modules/darwin/homebrew.nix) for parity with vendor distribution.
  home.packages = with pkgs; [
    jdk11
    jdk17
  ];
}

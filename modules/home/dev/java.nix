{ pkgs, ... }: {
  # One JDK at the user level — multiple JDKs in the same Nix profile
  # collide on shared resource paths (demo .jar files, etc.).
  # User has Zulu 21 via cask in modules/darwin/homebrew.nix; this
  # adds JDK 17 for projects that pin to it.
  #
  # If you need additional versions side-by-side (e.g. 11), add the
  # corresponding cask (`zulu@11`, `temurin@11`) instead of stacking
  # JDKs here.
  home.packages = with pkgs; [
    jdk17
  ];
}

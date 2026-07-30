{ pkgs, ... }: {
  # One JDK at the user level — multiple JDKs in the same Nix profile
  # collide on shared resource paths (demo .jar files, etc.).
  # Zulu 11 and 21 are installed as casks for side-by-side selection;
  # this adds JDK 17 for projects that pin to it.
  #
  # If you need additional versions side-by-side, add the
  # corresponding cask (`zulu@11`, `temurin@11`) instead of stacking
  # JDKs here.
  home.packages = with pkgs; [
    jdk17
  ];
}

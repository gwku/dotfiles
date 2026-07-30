{ pkgs, ... }: {
  # Android dev CLI tooling. The Android SDK manager itself is
  # installed via the `android-commandlinetools` cask so it can manage
  # platforms / build-tools / system images interactively.
  home.packages = with pkgs; [
    android-tools # adb, fastboot
    apktool
    gitRepo # AOSP `repo` tool
  ];

  # jadx is installed as a Homebrew formula in the Darwin configuration;
  # its current Nix build is broken on aarch64-darwin.
}

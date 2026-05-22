{ pkgs, ... }: {
  # Android dev CLI tooling. The Android SDK manager itself is
  # installed via the `android-commandlinetools` cask so it can manage
  # platforms / build-tools / system images interactively.
  home.packages = with pkgs; [
    android-tools  # adb, fastboot
    apktool
    gitRepo        # AOSP `repo` tool
  ];

  # jadx is not packaged cleanly on aarch64-darwin (pulls a broken
  # python `av` build chain). Install from
  # https://github.com/skylot/jadx/releases if needed.
}

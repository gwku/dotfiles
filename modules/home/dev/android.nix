{ pkgs, ... }: {
  # Android dev CLI tooling. The Android SDK manager itself is
  # installed via the `android-commandlinetools` cask so it can manage
  # platforms / build-tools / system images interactively.
  home.packages = with pkgs; [
    android-tools  # adb, fastboot
    apktool
    jadx
    gitRepo        # AOSP `repo` tool
  ];
}

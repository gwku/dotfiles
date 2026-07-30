{ pkgs, ... }: {
  # GUI apps that come from nixpkgs (not Homebrew casks).
  #
  # Most macOS GUI apps live in modules/darwin/homebrew.nix because
  # self-updating apps fight pinned Nix versions. Add an app here only
  # if you want strict reproducibility for it.
  environment.systemPackages = with pkgs; [
    firefox-bin
    mas
    vscode
    wezterm
  ];
}

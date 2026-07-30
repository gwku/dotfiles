{ pkgs, ... }: {
  programs.wezterm = {
    # On Darwin the package is installed system-wide so its app bundle exists
    # before nix-darwin generates Dock bookmarks. Linux still gets it through
    # Home Manager.
    enable = pkgs.stdenv.isLinux;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };

  # Embed the package's real store path. `/run/current-system/sw` exists on
  # NixOS/nix-darwin systems, but not with standalone Home Manager on Linux.
  xdg.configFile."wezterm/wezterm.lua".text =
    builtins.replaceStrings
      [ "@fish@" ]
      [ "${pkgs.fish}/bin/fish" ]
      (builtins.readFile ./wezterm.lua);
}

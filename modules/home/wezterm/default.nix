{ pkgs, ... }: {
  programs.wezterm = {
    # On Darwin the package is installed system-wide so its app bundle exists
    # before nix-darwin generates Dock bookmarks. Linux still gets it through
    # Home Manager.
    enable = pkgs.stdenv.isLinux;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}

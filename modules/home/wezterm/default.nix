{ ... }: {
  programs.wezterm = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
  xdg.configFile."wezterm/colors/neofusion.toml".source = ./colors-neofusion.toml;
}

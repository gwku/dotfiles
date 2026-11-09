{ username, ... }: {
  home = {
    inherit username;
    homeDirectory = "/Users/${username}";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
  programs.man.generateCaches = false;
}

{ pkgs, ... }: {
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  programs.lazygit.enable = true;

  home.packages = with pkgs; [
    gh-dash
  ];
}

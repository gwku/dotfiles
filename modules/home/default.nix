{ ... }: {
  imports = [
    ./shell/fish.nix
    ./shell/starship.nix
    ./shell/direnv.nix
    ./cli/core.nix
    ./cli/fzf.nix
    ./cli/zoxide.nix
    ./cli/bat.nix
    ./cli/eza.nix
    ./cli/gh.nix
    ./git.nix
    ./ssh.nix
    ./neovim
    ./wezterm
    ./dev
    ./fonts.nix
  ];
}

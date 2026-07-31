{ ... }: {
  imports = [
    ./shell/fish.nix
    ./shell/starship.nix
    ./shell/direnv.nix
    ./login-items.nix
    ./cli/core.nix
    ./cli/fzf.nix
    ./cli/zoxide.nix
    ./cli/bat.nix
    ./cli/btop.nix
    ./cli/eza.nix
    ./cli/gh.nix
    ./git.nix
    ./ssh.nix
    ./neovim
    ./wezterm
    ./cursor.nix
    ./dev
    ./fonts.nix
  ];
}

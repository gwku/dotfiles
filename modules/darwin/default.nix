{ ... }: {
  imports = [
    ./nix.nix
    ./tailscale.nix
    ./t3-firewall.nix
    ./remote-desktop.nix
    ./system-defaults.nix
    ./fonts.nix
    ./apps.nix
    ./homebrew.nix
  ];
}

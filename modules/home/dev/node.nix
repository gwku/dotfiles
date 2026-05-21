{ pkgs, ... }: {
  # Bun replaces volta + nvm — it ships its own runtime + package
  # manager. Per-project Node versions still possible via bun.
  home.packages = with pkgs; [
    bun
    nodejs_22
    pnpm
  ];
}

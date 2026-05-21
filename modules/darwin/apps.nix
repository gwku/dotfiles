{ pkgs, ... }: {
  # GUI apps available from nixpkgs on aarch64-darwin. Apps that aren't
  # packaged for darwin (OrbStack, Raycast, JetBrains Toolbox, etc.) are
  # listed in UNMANAGED.md and installed manually.
  environment.systemPackages = with pkgs; [
    firefox-bin
    vscode
    obsidian
    discord
  ];
}

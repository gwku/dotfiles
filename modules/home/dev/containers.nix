{ pkgs, ... }: {
  # OrbStack is installed through the nix-darwin Homebrew cask list.
  # These packages provide the client and Compose independently.
  home.packages = with pkgs; [
    docker-client
    docker-compose
  ];
}

{ pkgs, ... }: {
  # OrbStack is installed manually on macOS (see UNMANAGED.md). These
  # packages give the CLI side: docker client + ergonomics.
  home.packages = with pkgs; [
    docker-client
    docker-compose
    lazydocker
    dive
  ];
}

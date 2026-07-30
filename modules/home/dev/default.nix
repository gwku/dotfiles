{ pkgs, ... }: {
  imports = [
    ./python.nix
    ./node.nix
    ./rust.nix
    ./dotnet.nix
    ./java.nix
    ./php.nix
    ./android.nix
    ./db.nix
    ./ml.nix
    ./cloud.nix
    ./containers.nix
  ];

  home.packages = [
    pkgs.go
  ];
}

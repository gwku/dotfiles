{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    ripgrep
    fd
    jq
    yq-go
    httpie
    tree
    wget
    curl
    unzip
    gnused
    gnugrep
    htop
    btop
    tealdeer
    bitwarden-cli
    oath-toolkit
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    coreutils
    findutils
    gawk
  ];
}

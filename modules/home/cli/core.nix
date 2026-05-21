{ pkgs, lib, ... }: {
  home.packages = with pkgs; [
    # File / search
    ripgrep
    fd
    file
    tree
    poppler_utils
    p7zip
    innoextract
    wimlib

    # JSON / YAML / data
    jq
    yq-go

    # HTTP / network
    httpie
    wget
    curl
    inetutils
    hey
    sshpass
    wireguard-tools

    # Archives / compression
    unzip

    # System monitors
    htop
    btop
    procps  # provides `watch` on Darwin

    # Docs / help
    tealdeer

    # Secrets / auth
    bitwarden-cli
    oath-toolkit
    infisical

    # Media / images
    mpv
    ffmpeg

    # Recovery
    ddrescue

    # Build / dev hygiene
    cmake
    pre-commit

    # Web server
    nginx

    # POSIX baseline
    gnused
    gnugrep
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    coreutils
    findutils
    gawk
  ];
}

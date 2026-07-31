{ pkgs, lib, ... }: {
  home.packages =
    with pkgs;
    [
      # File / search
      ripgrep
      fd
      file
      tree
      poppler-utils
      p7zip
      innoextract
      wimlib
      exiftool

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
      pjsip

      # Archives / compression
      unzip

      # System monitors
      htop
      procps # provides `watch` on Darwin

      # Docs / help
      tealdeer

      # Secrets / auth
      bitwarden-cli
      gnupg
      oath-toolkit
      infisical

      # Media / images
      mpv
      ffmpeg
      yt-dlp

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
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      coreutils
      findutils
      gawk
    ];
}

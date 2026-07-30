{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cleanupBrewfile = pkgs.writeText "Brewfile-cleanup" config.homebrew.brewfile;
in
{
  # nix-homebrew installs and pins Homebrew itself via Nix so the
  # bootstrap is declarative. autoMigrate adopts the existing
  # /opt/homebrew if present.
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
  };

  # Current Homebrew requires explicit trust before loading formulae from
  # third-party taps. Run this after nix-homebrew creates the prefix and
  # immediately before nix-darwin's Homebrew bundle activation.
  system.activationScripts.setup-homebrew.text = lib.mkAfter ''
    if [[ -x /opt/homebrew/bin/brew ]]; then
      sudo --user=${username} --set-home \
        /opt/homebrew/bin/brew trust --tap \
        microsoft/mssql-release cirruslabs/cli
    fi
  '';

  # Current Homebrew makes `brew bundle --cleanup` a deprecated dry-run. Keep the
  # desired uninstall-without-zap behavior using its explicit cleanup command.
  system.activationScripts.homebrew.text = lib.mkAfter ''
    if [[ -x /opt/homebrew/bin/brew ]]; then
      sudo --user=${username} --set-home \
        env HOMEBREW_NO_AUTO_UPDATE=1 \
        /opt/homebrew/bin/brew bundle cleanup \
        --file=${cleanupBrewfile} --force
    fi
  '';

  # nix-darwin's homebrew module declares the actual cask/formula list.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Required for Microsoft's non-interactive ODBC/tool formulae.
      extraEnv = {
        HOMEBREW_ACCEPT_EULA = "Y";

        # Homebrew defaults to twice the CPU count, which is too aggressive
        # for a bootstrap downloading many large casks through one connection.
        HOMEBREW_DOWNLOAD_CONCURRENCY = "4";
        HOMEBREW_CURL_RETRIES = "10";
      };
      # The Brewfile is exhaustive. Remove packages no longer declared,
      # but preserve their user data: zap can delete unrelated state such
      # as ~/.dotnet, ~/.nuget, ~/.codex, and editor configuration.
      # Performed explicitly above for compatibility with current Homebrew.
      cleanup = "none";
    };

    # Extra taps for proprietary tools not on the default homebrew-cask.
    taps = [
      "microsoft/mssql-release"
      "cirruslabs/cli"
    ];

    # Brew formulae not (yet) in nixpkgs or where the brew distribution
    # is the canonical path.
    brews = [
      # Explicit runtime dependencies prevent `brew bundle cleanup` from
      # mistaking dependencies of the Microsoft formulae for undeclared
      # top-level packages.
      "ca-certificates"
      "libtool"
      "m4"
      "openssl@3"
      "unixodbc"

      "msodbcsql18"
      "mssql-tools18"
      "cirruslabs/cli/tart" # macOS VMs on Apple Silicon
      "jadx" # Nix build is currently broken on aarch64-darwin
    ];

    # Cask GUI apps. Apps that are reproducible from nixpkgs darwin
    # (e.g. nothing yet) can be moved to modules/darwin/apps.nix.
    casks = [
      # Window / menu bar / desktop
      "easy-move+resize"
      "itsycal"
      "jordanbaird-ice"
      "maccy"
      "scroll-reverser"

      # Browsers
      "google-chrome"
      "helium-browser"
      "zen"

      # Comms
      "bitwarden"
      "discord"
      "signal"
      "slack"
      "telegram"
      "thunderbird"
      "whatsapp"

      # AI
      "chatgpt"
      "claude"
      "claude-code@latest"
      "codex"
      "cursor"
      "lm-studio"

      # Dev / API tools
      "android-studio"
      "bruno"
      "burp-suite"
      "insomnia"
      "mitmproxy"
      "rider"

      # Containers / VMs / k8s
      "orbstack"
      "utm"
      "freelens"

      # Mobile / Android
      "android-commandlinetools"
      "openmtp"

      # Current .NET SDK (SDK 8 is also provided via Nix in dev/dotnet.nix)
      "dotnet-sdk"

      # JVM
      "zulu@11"
      "zulu@21"

      # Networking / Remote
      "teamviewer"
      "windows-app"

      # Files / Cloud
      "cyberduck"
      "nextcloud"

      # Media / Creative
      "audacity"
      "cog-app"
      "elgato-wave-link"
      "inkscape"
      "mp3tag"
      "obs"
      "upscayl"

      # Productivity
      "calibre"
      "libreoffice"
      "mactex-no-gui"
      "obsidian"

      # Utilities
      "balenaetcher"
    ];
  };
}

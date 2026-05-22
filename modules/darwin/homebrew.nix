{ username, ... }: {
  # nix-homebrew installs and pins Homebrew itself via Nix so the
  # bootstrap is declarative. autoMigrate adopts the existing
  # /opt/homebrew if present.
  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
  };

  # nix-darwin's homebrew module declares the actual cask/formula list.
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # "none" keeps any cask/formula that exists outside this list
      # untouched. Flip to "zap" once the list below is exhaustive and
      # you want unmanaged installs removed on switch.
      cleanup = "none";
    };

    # Extra taps for proprietary tools not on the default homebrew-cask.
    taps = [
      "microsoft/mssql-release"
    ];

    # Brew formulae not (yet) in nixpkgs or where the brew distribution
    # is the canonical path.
    brews = [
      "msodbcsql17"
      "mssql-tools"
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

      # Comms
      "bitwarden"
      "discord"
      "signal"
      "slack"
      "telegram"
      "whatsapp"

      # AI coding
      "claude-code@latest"
      "cursor"

      # Dev / API tools
      "insomnia"
      "mitmproxy"

      # Containers / VMs / k8s
      "orbstack"
      "utm"
      "freelens"

      # Mobile / Android
      "android-commandlinetools"

      # .NET (SxS for SDK 10; SDK 8 is provided via Nix in dev/dotnet.nix)
      "dotnet-sdk10-0-100"

      # JVM
      "zulu@21"

      # Networking / Remote
      "teamviewer"
      "windows-app"

      # Files / Cloud
      "nextcloud"

      # Media / Creative
      "audacity"
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

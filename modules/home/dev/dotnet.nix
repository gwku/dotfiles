{ pkgs, ... }: {
  # .NET 8 LTS via Nix. .NET 10 is installed side-by-side as a brew
  # cask (modules/darwin/homebrew.nix) because the cask channel tracks
  # Microsoft's SxS layout exactly and self-updates to GA → patches.
  home.packages = with pkgs; [
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_8_0
    ])
  ];

  home.sessionVariables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
  };
}

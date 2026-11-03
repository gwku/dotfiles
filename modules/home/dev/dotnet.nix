{ pkgs, ... }: {
  # Keep both SDKs in one installation: the dotnet host on PATH only
  # discovers SDKs in its own root, not a separate Homebrew installation.
  home.packages = with pkgs; [
    (dotnetCorePackages.combinePackages [
      dotnetCorePackages.sdk_10_0
      dotnetCorePackages.sdk_8_0
    ])
  ];

  home.sessionVariables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
  };
}

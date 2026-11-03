{ lib, pkgs, ... }: {
  # On macOS this is only a launcher for the Homebrew-managed installation.
  # Linux combines the SDKs through Nix because Homebrew is macOS-only here.
  home.packages = [
    (pkgs.callPackage ../../../packages/dotnet { })
  ];

  home.sessionVariables = {
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    DOTNET_NOLOGO = "1";
  } // lib.optionalAttrs pkgs.stdenv.isDarwin {
    DOTNET_ROOT = "/usr/local/share/dotnet";
  };
}

{ dotnetCorePackages, lib, stdenv, writeShellScriptBin }:
if stdenv.hostPlatform.isDarwin then
  # Keep Nix's PATH precedence without pinning or shadowing the Brew SDKs.
  writeShellScriptBin "dotnet" ''
    export DOTNET_ROOT=/usr/local/share/dotnet
    exec "$DOTNET_ROOT/dotnet" "$@"
  ''
else
  let
    # Use updated release metadata with the pinned Nix packaging machinery.
    # McHub's preview C# syntax requires the compiler from the 10.0.4xx band.
    sdk10 = (dotnetCorePackages.buildDotnetSdk ./releases.nix).sdk_10_0_4xx;
  in
  assert lib.versionAtLeast sdk10.version "10.0.400";
  dotnetCorePackages.combinePackages [
    sdk10
    dotnetCorePackages.sdk_8_0
  ]

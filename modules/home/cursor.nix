{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.cursor = {
    enable = true;

    # Cursor itself is kept current by Homebrew. Home Manager only owns
    # the public extension set and leaves Cursor's bundled anysphere.*
    # extensions alone.
    package = null;
    mutableExtensionsDir = true;

    profiles.default.extensions =
      let
        marketplace = pkgs.nix-vscode-extensions.vscode-marketplace;
      in
      with marketplace;
      [
        anthropic.claude-code
        astro-build.astro-vscode
        bradlc.vscode-tailwindcss
        devsense.composer-php-vscode
        devsense.intelli-php-vscode
        devsense.phptools-vscode
        devsense.profiler-php-vscode
        dotjoshjohnson.xml
        fwcd.kotlin
        hashicorp.terraform
        ms-dotnettools.vscode-dotnet-runtime
        ms-python.debugpy
        ms-python.python
        mtxr.sqltools-driver-sqlite
        mtxr.sqltools
        saoudrizwan.claude-dev
        unifiedjs.vscode-mdx
        vscjava.vscode-gradle
        vue.volar
      ];
  };
}

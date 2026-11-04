{ pkgs, lib, ... }:
let
  forgejoCli =
    if lib.versionAtLeast pkgs.forgejo-cli.version "0.6.0" then
      pkgs.forgejo-cli
    else
      pkgs.callPackage ../../../packages/forgejo-cli { };
in
lib.mkIf pkgs.stdenv.isLinux {
  home.packages = [ forgejoCli ];
  # Authentication stays in fj's private, writable user data directory.
  # Never put API tokens into the Nix store or a generated shell wrapper.
}

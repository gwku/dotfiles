{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isLinux {
  # Install the client only. OS permissions, privileged input service, local
  # identities, passwords, and session approval stay machine-local.
  home.packages = [ pkgs.rustdesk ];
}

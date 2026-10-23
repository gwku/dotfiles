{ lib, ... }:
let
  # Portable T3 Code preferences only. Window bounds, auth tokens, secrets,
  # the environment id, and the SQLite state stay machine-local.
  files = [
    "settings.json"
    "keybindings.json"
    "client-settings.json"
  ];
in
{
  # T3 Code rewrites these files itself, so they are copied as regular
  # writable files instead of read-only store symlinks. Each switch restores
  # the versions committed here.
  home.activation.installT3CodeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.t3/userdata"
    ${lib.concatMapStringsSep "\n" (f: ''
      run install -m 644 ${./. + "/${f}"} "$HOME/.t3/userdata/${f}"
    '') files}
  '';
}

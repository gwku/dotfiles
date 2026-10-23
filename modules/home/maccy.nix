{ lib, pkgs, ... }:
let
  preferences = {
    KeyboardShortcuts_delete = "{\"carbonModifiers\":2048,\"carbonKeyCode\":51}";
    KeyboardShortcuts_pin = "{\"carbonModifiers\":2048,\"carbonKeyCode\":35}";
    KeyboardShortcuts_popup = "{\"carbonModifiers\":2304,\"carbonKeyCode\":9}";
    KeyboardShortcuts_togglePreview = "{\"carbonKeyCode\":49,\"carbonModifiers\":4096}";
    SUEnableAutomaticChecks = false;
    enabledPasteboardTypes = [
      "public.jpeg"
      "public.heic"
      "public.html"
      "public.file-url"
      "public.rtf"
      "public.utf8-plain-text"
      "public.tiff"
      "public.png"
    ];
    historySize = 999;
    previewWidth = 400;
    showFooter = true;
    showInStatusBar = false;
    showSearch = true;
    showTitle = true;
    suppressClearAlert = false;
    windowSize = "[450,800]";
  };
  restorePreferences = pkgs.writeShellApplication {
    name = "restore-maccy-preferences";
    text = lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: ''
      /usr/bin/defaults write org.p0deje.Maccy ${lib.escapeShellArg key} ${
        lib.escapeShellArg (lib.generators.toPlist { escape = true; } value)
      }
    '') preferences);
  };
in
lib.mkIf pkgs.stdenv.isDarwin {
  home.packages = [ restorePreferences ];

  # macOS can deny access to another app's container even during a root
  # activation. Keep the rest of the switch usable and provide a manual
  # retry command for a terminal with access to Maccy's preferences.
  home.activation.restoreMaccyPreferences = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! run ${restorePreferences}/bin/restore-maccy-preferences; then
      echo "warning: macOS blocked Maccy preference restoration; other settings will continue." >&2
      echo "Run restore-maccy-preferences from a terminal permitted to access Maccy app data, then rerun the smoke test." >&2
    fi
  '';
}

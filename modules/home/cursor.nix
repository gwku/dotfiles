{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.isDarwin {
  programs.cursor = {
    enable = true;

    # Cursor itself is kept current by Homebrew. Home Manager only owns
    # the public extension set and leaves Cursor's bundled anysphere.*
    # extensions alone.
    package = null;
    mutableExtensionsDir = true;

    profiles.default = {
      # Portable editor preferences only. remote.SSH.remotePlatform stays
      # machine-local because its host aliases are private Bitwarden metadata.
      userSettings = {
        "window.commandCenter" = true;
        "git.autofetch" = true;
        "git.enableSmartCommit" = true;
        "javascript.updateImportsOnFileMove.enabled" = "always";
        "git.confirmSync" = false;
        "[vue]"."editor.defaultFormatter" = "Vue.volar";
        "diffEditor.ignoreTrimWhitespace" = false;
        "cursor.composer.queueMessageDefaultBehavior" = "queue";
        "[mdx]"."editor.defaultFormatter" = "unifiedjs.vscode-mdx";
        "sqltools.useNodeRuntime" = true;
        "workbench.colorTheme" = "Cursor Light";
        "claudeCode.preferredLocation" = "sidebar";
        "window.autoDetectColorScheme" = false;
        "explorer.confirmDelete" = false;
      };

      keybindings = [
        {
          key = "cmd+i";
          command = "composerMode.agent";
        }
        {
          key = "shift+enter";
          command = "workbench.action.terminal.sendSequence";
          args.text = builtins.fromJSON ''"\u001b\r"'';
          when = "terminalFocus";
        }
      ];

      extensions =
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
  };
}

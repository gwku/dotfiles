{ lib, pkgs, ... }: {
  home.sessionVariables = lib.mkIf pkgs.stdenv.isDarwin {
    HOMEBREW_NO_ANALYTICS = "1";
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "eza -lah --git --group-directories-first";
      ls = "eza --group-directories-first";
      lt = "eza --tree --level=2 --git-ignore";
      cat = "bat --paging=never";
      grep = "rg";

      g = "git";
      gs = "git status";
      gd = "git diff";
      gl = "git log --oneline --graph --decorate";
      gco = "git checkout";
      gcm = "git commit -m";

      k = "kubectl";
      tf = "tofu";
    };

    shellAbbrs = {
      nfu = "nix flake update --flake ~/development/dotfiles";
      nfc = "nix flake check ~/development/dotfiles";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      drs = "~/development/dotfiles/scripts/switch.sh";
    }
    // lib.optionalAttrs pkgs.stdenv.isLinux {
      hms = "~/development/dotfiles/scripts/switch.sh workstation";
    };

    shellInit = ''
      set -gx EDITOR nvim
      set -gx VISUAL nvim
      set -gx PAGER less
      set -gx LESS "-R --use-color"
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
    '';

    interactiveShellInit = ''
      set fish_greeting

      # Source machine-local, non-committed paths and settings.
      if test -f ~/.config/fish/conf.d/local.fish
        source ~/.config/fish/conf.d/local.fish
      end
    '';

    functions = {
      mkcd = ''
        mkdir -p $argv[1]; and cd $argv[1]
      '';

      # nvm for fish. The real nvm lives in ~/.nvm (see UNMANAGED.md) and runs through
      # bash; the resulting PATH is copied back so `nvm use` and `nvm install` work.
      nvm = {
        description = "Node Version Manager (real nvm via bash)";
        body = ''
          if not test -s $HOME/.nvm/nvm.sh
            echo "nvm is not installed in ~/.nvm" >&2
            return 1
          end

          bash -c '. "$HOME/.nvm/nvm.sh" --no-use; nvm "$@"' nvm $argv
          set -l nvm_status $status

          if test $nvm_status -eq 0; and contains -- "$argv[1]" use install deactivate
            set -l use_args $argv
            if test "$argv[1]" = install
              set use_args use $argv[2]
            end
            set -l new_path (bash -c '. "$HOME/.nvm/nvm.sh" --no-use; nvm "$@" >/dev/null 2>&1; printf %s "$PATH"' nvm $use_args)
            if test -n "$new_path"
              set -gx PATH (string split : -- $new_path)
            end
          end
          return $nvm_status
        '';
      };

      # Switch Node automatically when a directory has a .nvmrc.
      __nvm_auto_use = {
        description = "Run nvm use when entering a directory with .nvmrc";
        onVariable = "PWD";
        body = ''
          status is-interactive; or return
          test -f .nvmrc; or return
          test -s $HOME/.nvm/nvm.sh; or return
          nvm use >/dev/null 2>&1
        '';
      };

      bw-load-secrets = ''
        # Unlock Bitwarden once per shell, then export selected secrets
        # into the current session. The vault and item IDs are
        # configured per-machine; this function only orchestrates.
        if not type -q bw
          echo "bitwarden-cli (bw) not found" >&2
          return 1
        end
        set -x BW_SESSION (bw unlock --raw)
        echo "Bitwarden unlocked. Use 'bw get item <name>' to fetch."
      '';
    };

    plugins = [
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "autopair";
        src = pkgs.fishPlugins.autopair.src;
      }
      {
        name = "puffer";
        src = pkgs.fishPlugins.puffer.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];
  };
}

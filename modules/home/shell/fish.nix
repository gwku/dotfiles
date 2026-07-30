{ lib, pkgs, ... }: {
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
      drs = "~/development/dotfiles/scripts/switch.sh gkmp";
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

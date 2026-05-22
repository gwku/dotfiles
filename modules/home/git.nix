{ pkgs, user, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;

    userName  = user.fullName;
    userEmail = user.email;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      color.ui = "auto";
      diff.algorithm = "histogram";
      merge.conflictStyle = "zdiff3";
      core.editor = "nvim";
    };

    aliases = {
      st = "status -sb";
      co = "checkout";
      br = "branch";
      ci = "commit";
      lg = "log --oneline --graph --decorate --all";
      last = "log -1 HEAD --stat";
      unstage = "reset HEAD --";
    };

    ignores = [
      ".DS_Store"
      ".direnv"
      "result"
      "result-*"
      ".idea"
      ".vscode"
      "*.swp"
      ".envrc.local"
    ];

    # Signing key is configured per-machine (id only — actual key in
    # ssh-agent or GPG). Override programs.git.signing in host home.nix
    # to enable.
  };

  programs.git-lfs.enable = true;

  home.packages = with pkgs; [
    git-filter-repo
    delta
  ];
}

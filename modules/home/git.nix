{ pkgs, user, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;

    settings = {
      user.name  = user.fullName;
      user.email = user.email;

      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      rebase.autoStash = true;
      fetch.prune = true;
      color.ui = "auto";
      diff.algorithm = "histogram";
      merge.conflictStyle = "zdiff3";
      core.editor = "nvim";

      alias = {
        st = "status -sb";
        co = "checkout";
        br = "branch";
        ci = "commit";
        lg = "log --oneline --graph --decorate --all";
        last = "log -1 HEAD --stat";
        unstage = "reset HEAD --";
      };
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
  };

  home.packages = with pkgs; [
    git-filter-repo
    delta
  ];
}

{ pkgs, user, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    lfs.enable = true;

    settings = {
      user.name = user.fullName;
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

      # MC GitHub repositories are backup copies. Fetches remain on GitHub;
      # pushes to their normal URLs fail locally, including fresh clones.
      url."github-backup-push-blocked://MarketingConcurrent/".pushInsteadOf = [
        "https://github.com/MarketingConcurrent/"
        "http://github.com/MarketingConcurrent/"
        "git@github.com:MarketingConcurrent/"
        "ssh://git@github.com/MarketingConcurrent/"
        "ssh://git@github.com:22/MarketingConcurrent/"
        "git://github.com/MarketingConcurrent/"
        "https://github.com/marketingconcurrent/"
        "http://github.com/marketingconcurrent/"
        "git@github.com:marketingconcurrent/"
        "ssh://git@github.com/marketingconcurrent/"
        "ssh://git@github.com:22/marketingconcurrent/"
        "git://github.com/marketingconcurrent/"
      ];
      protocol.github-backup-push-blocked.allow = "never";

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

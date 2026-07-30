{
  config,
  inputs,
  pkgs,
  username,
  ...
}:
{
  # Determinate owns the daemon and base nix.conf. Its nix-darwin module
  # disables nix-darwin's conflicting native Nix management and writes our
  # additional settings to /etc/nix/nix.custom.conf.
  determinateNix = {
    enable = true;

    customSettings = {
      auto-optimise-store = true;
      trusted-users = [
        "root"
        "@admin"
        username
      ];
    };

    determinateNixd.garbageCollector.strategy = "automatic";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];

  # Fish at the system level so the host activation can select it as the
  # login shell for the existing macOS account.
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Terminal launches Fish directly, so the POSIX path_helper used by zsh
  # never runs. Export nix-darwin's complete system path through Fish's
  # foreign-environment bridge before Homebrew and user plugins initialize.
  environment.shellInit = ''
    export PATH="${config.environment.systemPath}:$PATH"
  '';
}

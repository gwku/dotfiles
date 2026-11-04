{ lib, pkgs, ... }: {
  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
    };
  };

  programs.lazygit.enable = true;

  home.packages = with pkgs; [
    gh-dash
    act # run GitHub Actions locally
    stripe-cli
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    # GUI agents inherit the Nix profile PATH, without Homebrew's bin directory.
    (pkgs.writeShellScriptBin "fj" ''
      exec /opt/homebrew/bin/fj "$@"
    '')
    (pkgs.writeShellScriptBin "mc-forgejo-login" ''
      export PATH="${lib.makeBinPath [ pkgs.infisical ]}:$PATH"
      exec ${pkgs.python3}/bin/python3 ${../../../packages/forgejo/login.py} "$@"
    '')
  ];
}

{ pkgs, ... }:
let
  nodejs = if pkgs.stdenv.hostPlatform.system == "aarch64-darwin"
    then pkgs.callPackage ../../../packages/node-security { }
    else pkgs.nodejs_22;
in {
  # Keep globally useful Node CLIs in the Nix profile instead of a
  # mutable /opt/homebrew/lib/node_modules tree.
  # Version pins and the npm dependency lock live in packages/node-tools.
  #
  # Bun replaces volta + nvm — it ships its own runtime + package
  # manager. Per-project Node versions still possible via bun.
  home.packages = with pkgs; [
    bun
    nodejs
    (pnpm.override { inherit nodejs; })
    (callPackage ../../../packages/node-tools { nodejs_22 = nodejs; })
  ];
}

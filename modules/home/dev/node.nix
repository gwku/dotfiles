{ pkgs, ... }:
let
  nodejs = pkgs.callPackage ../../../packages/node-security { };
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

{ pkgs, ... }: {
  # Use rustup as the launcher — it manages toolchains itself
  # (stable/nightly per project). Avoids pinning rustc via Nix when
  # not needed.
  home.packages = with pkgs; [
    rustup
  ];
}

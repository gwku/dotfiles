{ pkgs, ... }: {
  home.packages = with pkgs; [
    ollama
  ];

  # huggingface-cli isn't a first-class nixpkgs package; install
  # ad-hoc with `uv tool install huggingface-hub` when needed.
}

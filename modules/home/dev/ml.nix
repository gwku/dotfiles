{ pkgs, ... }: {
  home.packages = with pkgs; [
    ollama
  ];

  # The Hugging Face CLI is provided by python.nix.
}

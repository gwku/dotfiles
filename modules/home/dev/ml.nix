{ pkgs, ... }: {
  home.packages = with pkgs; [
    ollama
    huggingface-cli
  ];
}

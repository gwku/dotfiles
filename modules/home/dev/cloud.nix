{ pkgs, ... }: {
  home.packages = with pkgs; [
    awscli2
    azure-cli
    kubectl
    kubernetes-helm
    k9s
    cloudflared
    terraform
  ];
}

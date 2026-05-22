{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Cloud providers
    awscli2
    azure-cli
    cloudflared

    # Kubernetes
    kubectl
    kubernetes-helm
    k9s
    kind
    kustomize
    talosctl

    # IaC
    opentofu
  ];
}

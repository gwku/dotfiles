{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Cloud providers
    awscli2
    cloudflared

    # Kubernetes
    kubectl
    kubernetes-helm
    kind
    kustomize
    talosctl

    # IaC
    opentofu
  ];
}

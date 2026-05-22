{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Cloud providers
    awscli2

    # Kubernetes
    kubectl
    kubernetes-helm
    kind
    kustomize

    # IaC
    opentofu
  ];
}

{ pkgs, ... }: {
  # Global Python is intentionally minimal. Per-project versions and
  # dependencies are managed by uv in a project-local .venv.
  home.packages = with pkgs; [
    python313
    uv
    pipx
    ruff
  ];
}

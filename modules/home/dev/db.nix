{ pkgs, ... }: {
  # mssql-tools18 lives in modules/darwin/homebrew.nix because the
  # microsoft/mssql-release tap is the only realistic source.
  home.packages = with pkgs; [
    mariadb # brings server + client + connector-c
    postgresql_18 # PostgreSQL tools, including psql
    pgloader
    sqlite
  ];
}

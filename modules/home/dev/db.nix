{ pkgs, ... }: {
  # mssql-tools lives in modules/darwin/homebrew.nix because the
  # microsoft/mssql-release tap is the only realistic source.
  home.packages = with pkgs; [
    mariadb
    libmysqlclient
    pgloader
    sqlite
  ];
}

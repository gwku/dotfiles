{ pkgs, ... }: {
  home.packages = with pkgs; [
    php83
    php83Packages.composer
    php-cs-fixer
  ];
}

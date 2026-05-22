{
  description = "dotfiles — nix-darwin + Home Manager (macOS + Linux)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , nix-darwin
    , nix-homebrew
    , ...
    }@inputs:
    let
      # Single source of truth for identity. Change here, everything
      # else picks it up via specialArgs.
      user = {
        name     = "gwku";
        fullName = "Gerwin Kuijntjes";
        email    = "administratie@gerwinkuijntjes.nl";
      };

      # Back-compat: keep `username` available too, so modules that
      # only care about the short name don't have to destructure.
      username = user.name;

      mkDarwin = host: system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs user username; };
          modules = [
            ./modules/darwin
            ./hosts/darwin
            ./hosts/darwin/${host}
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs user username; };
              home-manager.users.${user.name} = import ./hosts/darwin/${host}/home.nix;
              home-manager.sharedModules = [ ./modules/home ];
            }
          ];
        };

      mkHome = host: system:
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs user username; };
          modules = [
            ./modules/home
            ./hosts/linux/${host}/home.nix
          ];
        };
    in
    {
      darwinConfigurations = {
        gkmp = mkDarwin "gkmp" "aarch64-darwin";
      };

      homeConfigurations = {
        "${user.name}@workstation" = mkHome "workstation" "x86_64-linux";
      };
    };
}

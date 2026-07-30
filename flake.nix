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

    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";

      # The cask tap is updated during activation, so its DSL must not outrun
      # an old transitive Homebrew parser pin.
      inputs.brew-src = {
        url = "github:Homebrew/brew";
        flake = false;
      };
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nix-homebrew,
      ...
    }@inputs:
    let
      # Single source of truth for identity. Change here, everything
      # else picks it up via specialArgs.
      user = {
        name = "gwku";
        fullName = "Gerwin Kuijntjes";
        email = "administratie@gerwinkuijntjes.nl";
      };

      # Back-compat: keep `username` available too, so modules that
      # only care about the short name don't have to destructure.
      username = user.name;

      mkDarwin =
        host: system:
        nix-darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { inherit inputs user username; };
          modules = [
            inputs.determinate.darwinModules.default
            ./modules/darwin
            ./hosts/darwin
            ./hosts/darwin/${host}
            nix-homebrew.darwinModules.nix-homebrew
            home-manager.darwinModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = { inherit inputs user username; };
                users.${user.name} = import ./hosts/darwin/${host}/home.nix;
                sharedModules = [ ./modules/home ];
              };
            }
          ];
        };

      mkHome =
        host: system:
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

      # Use the nix-darwin revision pinned by this flake for bootstrap
      # and rebuilds instead of resolving a moving registry entry.
      packages = {
        aarch64-darwin = {
          darwin-rebuild = nix-darwin.packages.aarch64-darwin.darwin-rebuild;
          node-tools = nixpkgs.legacyPackages.aarch64-darwin.callPackage ./packages/node-tools { };
        };
        x86_64-linux.home-manager = home-manager.packages.x86_64-linux.home-manager;
      };

      checks = {
        aarch64-darwin.gkmp = self.darwinConfigurations.gkmp.system;
        x86_64-linux.workstation = self.homeConfigurations."${user.name}@workstation".activationPackage;
      };
    };
}

{
  description = "herdr plugins packaged for Nix, plus a Home Manager module to enable them";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
    flake-utils.url = "github:numtide/flake-utils";

    # Only used by checks.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    home-manager,
  }:
    {
      overlays.default = final: _prev: {
        herdrPlugins = final.callPackage ./pkgs/herdr-plugins {};
      };

      homeModules = {
        default = self.homeModules.herdr;
        herdr = import ./modules/home-manager.nix {inherit self;};
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      herdrPlugins = pkgs.callPackage ./pkgs/herdr-plugins {};
      plugins = flake-utils.lib.filterPackages system herdrPlugins;
    in {
      legacyPackages = {inherit herdrPlugins;};

      packages = plugins;

      checks =
        plugins
        // {
          plugins-activation = import ./checks/plugins-activation.nix {inherit self pkgs home-manager;};
        };

      formatter = pkgs.alejandra;
    });
}

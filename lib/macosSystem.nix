{
  lib,
  inputs,
  darwin-modules,
  home-modules ? [],
  system,
  hostVars,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  ...
}: let
  inherit (inputs) nixpkgs-darwin home-manager nix-darwin;
in
  nix-darwin.lib.darwinSystem {
    inherit system;
    # Include hostVars in specialArgs to make them available in all modules
    specialArgs = specialArgs // { 
      inherit hostVars;
    };
    modules =
      darwin-modules
      ++ [
        ({lib, ...}: {
          nixpkgs.pkgs = import nixpkgs-darwin {
            inherit system; # refer the `system` parameter form outer scope recursively
            # To use chrome, we need to allow the installation of non-free software
            config.allowUnfree = true;
          };
        })
      ]
      ++ (
        lib.optionals ((lib.lists.length home-modules) > 0)
        [
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "home-manager.backup";

            home-manager.extraSpecialArgs = specialArgs // { 
              inherit hostVars;
            };
            home-manager.users."${hostVars.username}".imports = home-modules;
          }
        ]
      );
  }

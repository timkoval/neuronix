{
  lib,
  inputs,
  darwin-modules,
  home-modules ? [],
  system,
  hostVariables,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  ...
}: let
  inherit (inputs) nixpkgs-darwin home-manager nix-darwin;
in
  nix-darwin.lib.darwinSystem {
    inherit system;
    # Include hostVariables in specialArgs to make them available in all modules
    specialArgs = specialArgs // { 
      # We set 'myvars = hostVariables' for backward compatibility
      myvars = hostVariables; 
      # Also include a new direct reference for modules that want to use it explicitly
      hostVariables = hostVariables;
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
              myvars = hostVariables;
              hostVariables = hostVariables; 
            };
            home-manager.users."${hostVariables.username}".imports = home-modules;
          }
        ]
      );
  }

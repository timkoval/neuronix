{
  lib,
  inputs,
  nixos-modules,
  home-modules ? [],
  system,
  hostVars,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  ...
}: let
  inherit (inputs) nixpkgs home-manager nixos-generators;
in
  nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = specialArgs // { 
      inherit hostVars;
    };
    modules =
      nixos-modules
      ++ [
        nixos-generators.nixosModules.all-formats
      ]
      ++ (
        lib.optionals ((lib.lists.length home-modules) > 0)
        [
          home-manager.nixosModules.home-manager
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

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
  inherit (inputs) nixpkgs home-manager nixos-generators stylix;
in
  nixpkgs.lib.nixosSystem {
    # system is set via nixpkgs.hostPlatform in hardware-configuration.nix
    specialArgs =
      specialArgs
      // {
        inherit hostVars;
      };
    modules =
      nixos-modules
      ++ [
        nixos-generators.nixosModules.all-formats
        stylix.nixosModules.stylix
        # Wire the grok-build overlay centrally where inputs is available
        {
          nixpkgs.overlays = [(import ../overlays/grok-build.nix {inherit (inputs) grok-build-src;})];
        }
      ]
      ++ (
        lib.optionals ((lib.lists.length home-modules) > 0)
        [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "home-manager.backup";

            home-manager.extraSpecialArgs =
              specialArgs
              // {
                inherit hostVars;
              };
            home-manager.users."${hostVars.username}".imports = home-modules;
          }
        ]
      );
  }

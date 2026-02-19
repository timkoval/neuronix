# colmena - Remote Deployment via SSH
{
  inputs,
  lib,
  nixos-modules,
  home-modules ? [],
  system,
  hostVars,
  genSpecialArgs,
  specialArgs ? (genSpecialArgs system),
  tags,
  ssh-user ? hostVars.username,
  ...
}: let
  inherit (inputs) home-manager;
in
  {name, ...}: {
    deployment = {
      targetUser = ssh-user;
      targetHost = name; # hostName or IP address
      tags = tags;
    };

    imports =
      nixos-modules
      ++ (
        lib.optionals ((lib.lists.length home-modules) > 0)
        [
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "home-manager.backup";

            home-manager.extraSpecialArgs = specialArgs // { inherit hostVars; };
            home-manager.users."${hostVars.username}".imports = home-modules;
          }
        ]
      );
  }

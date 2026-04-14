{
  inputs,
  lib,
  mylib,
  system,
  genSpecialArgs,
  ...
} @ args: let
  name = "tk-elitebook";

  hostVars = import (mylib.relativeToRoot "hosts/books/hp_450/variables.nix") {inherit lib;};

  base-modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/nixos/desktop.nix"
      "hosts/books/hp_450"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/desktop.nix"
      "hosts/books/hp_450/home.nix"
    ];
  };

  modules-hyprland = {
    nixos-modules =
      [
        {
          modules.desktop.wayland.enable = true;
        }
      ]
      ++ base-modules.nixos-modules;
    home-modules =
      [
        {
          modules.desktop.hyprland.enable = true;
        }
      ]
      ++ base-modules.home-modules;
  };

  modules-niri = {
    nixos-modules =
      [
        {
          modules.desktop.wayland.enable = true;
        }
      ]
      ++ base-modules.nixos-modules;
    home-modules =
      [
        {
          modules.desktop.niri.enable = true;
        }
      ]
      ++ base-modules.home-modules;
  };

  hyprlandArgs = modules-hyprland // args // {inherit hostVars;};
  niriArgs = modules-niri // args // {inherit hostVars;};
in {
  nixosConfigurations = {
    "${name}-hyprland" = mylib.nixosSystem hyprlandArgs;
    "${name}-niri" = mylib.nixosSystem niriArgs;
  };
}

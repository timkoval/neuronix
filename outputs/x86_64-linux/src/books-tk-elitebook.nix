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

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/nixos/desktop.nix"
      "hosts/books/hp_450"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/desktop.nix"
      "hosts/books/hp_450/home.nix"
    ];
  };

  systemArgs = modules // args // {inherit hostVars;};
in {
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;
}

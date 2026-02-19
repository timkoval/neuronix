{
  inputs,
  lib,
  mylib,
  system,
  genSpecialArgs,
  ...
} @ args: let
  name = "rpi4-example";
  tags = ["arm" "node" name];

  hostVars = import (mylib.relativeToRoot "hosts/nodes/${name}/variables.nix") {inherit lib;};

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      "modules/nixos/profiles/embedded.nix"
      "hosts/nodes/${name}"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/minimal.nix"
      "hosts/nodes/${name}/home.nix"
    ];
  };

  systemArgs = modules // args // {inherit hostVars;};
in {
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;

  colmenaMeta = {
    nodeNixpkgs.${name} = import inputs.nixpkgs {inherit system;};
    nodeSpecialArgs.${name} = (genSpecialArgs system) // {inherit hostVars;};
  };

  colmena.${name} = mylib.colmenaSystem (systemArgs // {inherit tags;});
}

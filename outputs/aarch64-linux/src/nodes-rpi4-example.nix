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
      "images/sd-card-minimal.nix"
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

  packages."${name}-sd-aarch64" = inputs.self.nixosConfigurations.${name}.config.formats.sd-aarch64;

  colmenaMeta = {
    nodeNixpkgs.${name} = import inputs.nixpkgs {inherit system;};
    nodeSpecialArgs.${name} = (genSpecialArgs system) // {inherit hostVars;};
  };

  colmena.${name} = mylib.colmenaSystem (systemArgs // {inherit tags;});
}

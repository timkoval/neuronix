{
  # NOTE: the args not used in this file CAN NOT be removed!
  # because haumea pass argument lazily,
  # and these arguments are used in the functions like `mylib.nixosSystem`, `mylib.colmenaSystem`, etc.
  inputs,
  lib,
  mylib,
  system,
  genSpecialArgs,
  ...
} @ args:
let
  name = "hetzner-tk";
  tags = ["hetzner" name];
  ssh-user = "tkoval";

  hostVars = import (mylib.relativeToRoot "hosts/clouds/hetzner-tk/variables.nix") { inherit lib; };

  modules = {
    nixos-modules = map mylib.relativeToRoot [
      # "secrets/nixos.nix"  # TODO: enable when secrets are ready
      "modules/nixos/server/server.nix"
      "hosts/clouds/hetzner-tk"
    ];
    home-modules = map mylib.relativeToRoot [
      "home/linux/server.nix"
    ];
  };

  systemArgs = modules // args // { inherit hostVars; };
in
{
  nixosConfigurations.${name} = mylib.nixosSystem systemArgs;

  colmenaMeta = {
    nodeNixpkgs.${name} = import inputs.nixpkgs { inherit system; };
    nodeSpecialArgs.${name} = (genSpecialArgs system) // { inherit hostVars; };
  };

  colmena.${name} = mylib.colmenaSystem (systemArgs // { inherit tags ssh-user; });
}

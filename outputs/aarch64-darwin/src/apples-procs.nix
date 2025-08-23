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
} @ args: let
  name = "procs";

  # Import host-specific variables from the host directory
  hostVars = import (mylib.relativeToRoot "hosts/apples/${name}/variables.nix");

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        # common
        # "secrets/darwin.nix"
        "modules/darwin"
        # host specific
        "hosts/apples/${name}"
#        "hosts/apples/iso-remapping.nix"
      ])
      ++ [];
    home-modules = map mylib.relativeToRoot [
      "hosts/apples/${name}/home.nix"
      "home/darwin"
    ];
  };

  systemArgs = modules // args // { inherit hostVars; };
in {
  # macOS's configuration
  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}

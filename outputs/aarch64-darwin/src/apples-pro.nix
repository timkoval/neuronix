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
  name = "pro";

  # Import host-specific variables from the host directory
  hostVariables = import (mylib.relativeToRoot "hosts/darwin-${name}/variables.nix");

  modules = {
    darwin-modules =
      (map mylib.relativeToRoot [
        # common
        "secrets/darwin.nix"
        "modules/darwin"
        # host specific
        "hosts/apples/${name}"
        "hosts/apples/iso-remapping.nix"
      ])
      ++ [];
    home-modules = map mylib.relativeToRoot [
      "hosts/apples/${name}/home.nix"
      "home/darwin"
    ];
  };

  systemArgs = modules // args // { inherit hostVariables; };
in {
  # macOS's configuration
  darwinConfigurations.${name} = mylib.macosSystem systemArgs;
}

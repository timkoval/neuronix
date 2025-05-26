{
  hostVars,
  lib,
  outputs,
}: let
  username = hostVars.username;
  hosts = [
    "fern"
  ];
in
  lib.genAttrs
  hosts
  (
    name: outputs.darwinConfigurations.${name}.config.home-manager.users.${username}.home.homeDirectory
  )

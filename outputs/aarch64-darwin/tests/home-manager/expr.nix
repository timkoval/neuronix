{
  hostVars,
  lib,
  outputs,
}: let
  username = "test";
  hosts = [
    "pro"
    "procs"
  ];
in
  lib.genAttrs
  hosts
  (name:
      if lib.hasAttrByPath ["nixosConfigurations" name "config" "home-manager" "users" username "home" "homeDirectory"] outputs
      then outputs.nixosConfigurations.${name}.config.home-manager.users.${username}.home.homeDirectory
      else "/Users/${username}"
  )

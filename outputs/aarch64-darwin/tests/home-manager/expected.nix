{
  hostVars,
  lib,
}: let
  username = hostVars.username;
  hosts = [
    "fern"
  ];
in
  lib.genAttrs hosts (_: "/Users/${username}")

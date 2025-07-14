{
  hostVars,
  lib,
}: let
  username = "test";
  hosts = [
    "pro"
    "procs"
  ];
in
  lib.genAttrs hosts (_: "/Users/${username}")

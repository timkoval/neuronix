{
  hostVars,
  lib,
}: let
  username = "test";
  hosts = [
    "ai-hyprland"
  ];
in
  lib.genAttrs hosts (_: "/home/${username}")

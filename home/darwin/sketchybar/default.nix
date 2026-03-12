{config, ...}: let
  colors = config.lib.stylix.colors;
in {
  home.file = {
    # Static config files (items, plugins, sketchybarrc)
    ".config/sketchybar/sketchybarrc" = {
      source = ./config/sketchybarrc;
      executable = true;
    };
    ".config/sketchybar/items" = {
      source = ./config/items;
      recursive = true;
    };
    ".config/sketchybar/plugins" = {
      source = ./config/plugins;
      recursive = true;
    };

    # colors.sh — generated from Stylix palette (0xAARRGGBB format)
    ".config/sketchybar/colors.sh".text = ''
      #!/bin/bash

      export WHITE=0xffffffff

      export TRANSPARENT="0x44${colors.base00}"
      export TRANSPARENT_RED="0x88${colors.base08}"
      export TRANSPARENT_YELLOW="0x88${colors.base0A}"
      export TRANSPARENT_PURPLE="0x88${colors.base0E}"
    '';
  };
}

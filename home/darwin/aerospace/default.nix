{config, ...}: let
  colors = config.lib.stylix.colors;
  # Read the static toml and replace the hardcoded border colors
  tomlContent = builtins.readFile ./aerospace.toml;
  themed = builtins.replaceStrings
    ["active_color=0xffe1e3e4" "inactive_color=0xff494d64"]
    ["active_color=0xff${colors.base0D}" "inactive_color=0xff${colors.base02}"]
    tomlContent;
in {
  home.file.".aerospace.toml".text = themed;
}

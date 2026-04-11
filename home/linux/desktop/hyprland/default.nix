{
  pkgs,
  config,
  lib,
  ...
} @ args:
with lib; let
  cfg = config.modules.desktop.hyprland;
in {
  imports = [
    ./options
  ];

  options.modules.desktop.hyprland = {
    enable = mkEnableOption "hyprland compositor";
    shell.backend = mkOption {
      type = types.enum ["classic" "quickshell"];
      default = "classic";
      description = "Shell backend for Hyprland session.";
    };
    idle.backend = mkOption {
      type = types.enum ["swayidle" "hypridle"];
      default = "swayidle";
      description = "Idle manager backend for Hyprland session.";
    };
    screenshot.backend = mkOption {
      type = types.enum ["hyprshot"];
      default = "hyprshot";
      description = "Screenshot backend for Hyprland session.";
    };
    screenshot.annotator = mkOption {
      type = types.enum ["none" "satty"];
      default = "none";
      description = "Annotation tool used by screenshot helper keybinds.";
    };
    wallpaper.backend = mkOption {
      type = types.enum ["swaybg" "swww"];
      default = "swaybg";
      description = "Wallpaper backend used by startup tooling.";
    };
    wallpaper.video.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable mpvpaper for video wallpaper support.";
    };
    settings = lib.mkOption {
      type = with lib.types; let
        valueType =
          nullOr (oneOf [
            bool
            int
            float
            str
            path
            (attrsOf valueType)
            (listOf valueType)
          ])
          // {
            description = "Hyprland configuration value";
          };
      in
        valueType;
      default = {};
    };
  };

  config = mkIf cfg.enable (
    mkMerge ([
        {
          wayland.windowManager.hyprland.settings = cfg.settings;
        }
      ]
      ++ (import ./values args))
  );
}

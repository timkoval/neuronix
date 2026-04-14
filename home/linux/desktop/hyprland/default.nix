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
    screenshot.backend = mkOption {
      type = types.enum ["hyprshot"];
      default = "hyprshot";
      description = "Screenshot backend for Hyprland session.";
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
          # Enable shared Wayland desktop config (walker, mako, wlogout, packages, env vars)
          modules.desktop.wayland.enable = true;

          wayland.windowManager.hyprland.settings = cfg.settings;
        }
      ]
      ++ (import ./values args))
  );
}

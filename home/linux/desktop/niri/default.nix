{
  pkgs,
  config,
  lib,
  ...
} @ args:
with lib; let
  cfg = config.modules.desktop.niri;
in {
  imports = [
    ./options
  ];

  options.modules.desktop.niri = {
    enable = mkEnableOption "niri compositor";
  };

  config = mkIf cfg.enable (
    mkMerge ([
        {
          modules.desktop.wayland.enable = true;
        }
      ]
      ++ (import ./values args))
  );
}

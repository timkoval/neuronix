{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.desktop.wayland;
in {
  config = lib.mkIf cfg.enable {
    stylix.targets.firefox.profileNames = ["default"];

    programs = {
      google-chrome = {
        enable = false;
        commandLineArgs = [
          "--gtk-version=4"
          "--enable-features=UseOzonePlatform"
          "--ozone-platform=wayland"
          "--enable-wayland-ime"
        ];
      };

      chromium = {
        enable = true;
        commandLineArgs = [
          "--gtk-version=4"
          "--enable-features=UseOzonePlatform,WaylandWindowDecorations"
          "--ozone-platform=wayland"
          "--enable-wayland-ime"
        ];
      };

      brave.enable = false;

      firefox = {
        enable = true;
        enableGnomeExtensions = false;
        package = pkgs.firefox;
        profiles.default = {
          isDefault = true;
        };
      };
    };
  };
}

{
  pkgs,
  pkgs-unstable,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.desktop.wayland;
  quickshellPkg =
    if pkgs ? quickshell
    then pkgs.quickshell
    else pkgs-unstable.quickshell;
  sattyPkg =
    if pkgs ? satty
    then pkgs.satty
    else pkgs-unstable.satty;
in {
  imports = [
    ./walker.nix
    ./mako.nix
    ./wlogout.nix
    ./wayland-apps.nix
  ];

  options.modules.desktop.wayland = {
    enable = mkEnableOption "shared Wayland desktop configuration";
    shell.backend = mkOption {
      type = types.enum ["classic" "quickshell"];
      default = "classic";
      description = "Shell backend for Wayland session.";
    };
    idle.backend = mkOption {
      type = types.enum ["swayidle" "hypridle"];
      default = "swayidle";
      description = "Idle manager backend for Wayland session.";
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
  };

  config = mkIf cfg.enable {
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_WEBRENDER = "1";
      _JAVA_AWT_WM_NONREPARENTING = "1";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      GDK_BACKEND = "wayland";
      NEURONIX_SHELL_BACKEND = cfg.shell.backend;
      NEURONIX_IDLE_BACKEND = cfg.idle.backend;
      NEURONIX_SCREENSHOT_ANNOTATOR = cfg.screenshot.annotator;
    };

    home.packages =
      (with pkgs; [
        swaylock
        wlogout
        wl-clipboard
        libqalculate # qalc — calculator backend for walker
        brightnessctl
        grim
        slurp
        wf-recorder
        mako
        yad
        alsa-utils
        mpd
        mpc
        ncmpcpp
        networkmanagerapplet
      ])
      ++ lib.optionals (cfg.shell.backend == "classic") [
        pkgs.waybar
      ]
      ++ lib.optionals (cfg.shell.backend == "quickshell") [
        quickshellPkg
        pkgs.qt6.qtmultimedia
        pkgs.qt6.qt5compat
        pkgs.qt6.qtwebsockets
        pkgs.bc
        pkgs.inotify-tools
        pkgs.pamixer
        pkgs.acpi
        pkgs.iw
      ]
      ++ lib.optionals (cfg.idle.backend == "swayidle") [
        pkgs.swayidle
      ]
      ++ lib.optionals (cfg.idle.backend == "hypridle") [
        pkgs.hypridle
      ]
      ++ lib.optionals (cfg.wallpaper.backend == "swaybg") [
        pkgs.swaybg
      ]
      ++ lib.optionals (cfg.wallpaper.backend == "swww") [
        pkgs.swww
      ]
      ++ lib.optionals cfg.wallpaper.video.enable [
        pkgs.mpvpaper
      ]
      ++ lib.optionals (cfg.screenshot.annotator == "satty") [
        sattyPkg
      ];

    xdg.configFile."mpd" = {
      source = ../hyprland/conf/mpd;
      recursive = true;
    };
  };
}

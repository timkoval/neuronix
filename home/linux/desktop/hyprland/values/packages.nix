{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  ...
}: let
  cfg = config.modules.desktop.hyprland;
  quickshellPkg =
    if pkgs ? quickshell
    then pkgs.quickshell
    else pkgs-unstable.quickshell;
  sattyPkg =
    if pkgs ? satty
    then pkgs.satty
    else pkgs-unstable.satty;
in {
  home.packages =
    (with pkgs; [
      swaylock # locking the screen
      wlogout # logout menu
      wl-clipboard # copying and pasting
      hyprpicker # color picker
      brightnessctl # brightness control utility
      grim # taking screenshots
      slurp # selecting a region to screenshot
      wf-recorder # screen recording
      mako # the notification daemon, the same as dunst
      yad # a fork of zenity, for creating dialogs

      # audio
      alsa-utils # provides amixer/alsamixer/...
      mpd # for playing system sounds
      mpc # command-line mpd client
      ncmpcpp # a mpd client with a UI
      networkmanagerapplet # provide GUI app: nm-connection-editor
    ])
    ++ [
      pkgs-unstable.hyprshot # screenshot helper
    ]
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
}

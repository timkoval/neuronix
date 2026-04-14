{
  pkgs,
  pkgs-unstable,
  lib,
  config,
  ...
}: let
  cfg = config.modules.desktop.hyprland;
  wcfg = config.modules.desktop.wayland;
  colors = config.lib.stylix.colors.withHashtag;
in {
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      env = [
        "NIXOS_OZONE_WL,1"
        "MOZ_ENABLE_WAYLAND,1"
        "MOZ_WEBRENDER,1"
        "NEURONIX_SHELL_BACKEND,${wcfg.shell.backend}"
        "NEURONIX_IDLE_BACKEND,${wcfg.idle.backend}"
        "NEURONIX_SCREENSHOT_ANNOTATOR,${wcfg.screenshot.annotator}"
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];
    };
    package = pkgs.hyprland;
    extraConfig = builtins.readFile ../conf/hyprland.conf;
    systemd.enable = true;
  };

  services.hypridle = lib.mkIf (wcfg.idle.backend == "hypridle") {
    enable = true;
    settings = {
      general = {
        lock_cmd = "swaylock";
        before_sleep_cmd = "loginctl lock-session";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 900;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  home.file.".wayland-session" = {
    source = "${pkgs.hyprland}/bin/Hyprland";
    executable = true;
  };

  home.packages = [
    pkgs.hyprpicker
    pkgs-unstable.hyprshot
  ];

  xdg.configFile =
    {
      "hypr/scripts" = {
        source = ../conf/scripts;
        recursive = true;
      };
    }
    // lib.optionalAttrs (wcfg.shell.backend == "classic") {
      "hypr/waybar/config.jsonc" = {
        source = ../conf/waybar/config.jsonc;
      };
      "hypr/waybar/style.css".text = ''
        /* Color palette managed by Stylix */
        @define-color base00 ${colors.base00};
        @define-color base01 ${colors.base01};
        @define-color base02 ${colors.base02};
        @define-color base03 ${colors.base03};
        @define-color base04 ${colors.base04};
        @define-color base05 ${colors.base05};
        @define-color base06 ${colors.base06};
        @define-color base07 ${colors.base07};
        @define-color base08 ${colors.base08};
        @define-color base09 ${colors.base09};
        @define-color base0A ${colors.base0A};
        @define-color base0B ${colors.base0B};
        @define-color base0C ${colors.base0C};
        @define-color base0D ${colors.base0D};
        @define-color base0E ${colors.base0E};
        @define-color base0F ${colors.base0F};

        * {
          font-family: "JetBrainsMono Nerd Font";
          font-size: 12pt;
          font-weight: bold;
          border-radius: 8px;
          transition-property: background-color;
          transition-duration: 0.5s;
        }
        @keyframes blink_red {
          to {
            background-color: @base08;
            color: @base00;
          }
        }
        .warning,
        .critical,
        .urgent {
          animation-name: blink_red;
          animation-duration: 1s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }
        window#waybar {
          background-color: transparent;
          border: 2px solid alpha(@base01, 0.3);
        }
        window > box {
          margin-left: 5px;
          margin-right: 5px;
          margin-top: 5px;
          background-color: shade(@base00, 0.9);
          padding: 3px;
          padding-left: 8px;
          border: 2px none @base0C;
        }
        #workspaces {
          padding-left: 0px;
          padding-right: 4px;
        }
        #workspaces button {
          padding-top: 5px;
          padding-bottom: 5px;
          padding-left: 6px;
          padding-right: 6px;
        }
        #workspaces button.active {
          background-color: @base0C;
          color: @base00;
        }
        #workspaces button.urgent {
          color: @base00;
        }
        #workspaces button:hover {
          background-color: @base09;
          color: @base00;
        }
        tooltip {
          background: @base01;
        }
        tooltip label {
          color: @base05;
        }
        #custom-launcher {
          font-size: 20px;
          padding-left: 8px;
          padding-right: 6px;
          color: @base0D;
        }
        #mode,
        #clock,
        #memory,
        #temperature,
        #cpu,
        #mpd,
        #custom-wall,
        #backlight,
        #pulseaudio,
        #network,
        #battery,
        #custom-powermenu {
          padding-left: 10px;
          padding-right: 10px;
        }
        #memory {
          color: @base0C;
        }
        #cpu {
          color: @base0E;
        }
        #clock {
          color: @base05;
        }
        #idle_inhibitor {
          color: @base0E;
          padding-right: 8px;
        }
        #battery {
          min-width: 55px;
          color: @base0D;
        }
        #battery.charging,
        #battery.full,
        #battery.plugged {
          color: @base0B;
        }
        #battery.critical:not(.charging) {
          color: @base08;
          animation-name: blink;
          animation-duration: 0.5s;
          animation-timing-function: linear;
          animation-iteration-count: infinite;
          animation-direction: alternate;
        }
        #custom-wall {
          color: @base0C;
        }
        #temperature {
          color: @base0D;
        }
        #backlight {
          color: @base09;
        }
        #pulseaudio {
          color: @base06;
        }
        #network {
          color: @base0B;
        }
        #network.disconnected {
          color: @base05;
        }
        #custom-powermenu {
          color: @base08;
          padding-right: 8px;
        }
        #tray {
          padding-right: 8px;
          padding-left: 10px;
        }
        #mpd.paused {
          color: @base03;
          font-style: italic;
        }
        #mpd.stopped {
          background: transparent;
        }
        #mpd {
          color: @base0D;
        }
      '';
    };
}

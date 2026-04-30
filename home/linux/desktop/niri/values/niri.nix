{
  pkgs,
  lib,
  config,
  ...
}: let
  wcfg = config.modules.desktop.wayland;
  colors = config.lib.stylix.colors.withHashtag;
in {
  home.file.".wayland-session" = {
    source = "${pkgs.niri}/bin/niri-session";
    executable = true;
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
      ];
    };
  };

  xdg.configFile =
    {
      "niri/config.kdl" = {
        source = ../conf/niri.kdl;
      };
      "niri/scripts" = {
        source = ../conf/scripts;
        recursive = true;
      };
    }
    // lib.optionalAttrs (wcfg.shell.backend == "classic") {
      "niri/waybar/config.jsonc" = {
        source = ../../hyprland/conf/waybar/config.jsonc;
      };
      "niri/waybar/style.css".text = ''
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
          border-radius: 4px;
          transition-property: background-color;
          transition-duration: 0.5s;
        }
        @keyframes blink_red {
          to {
            background-color: @base08;
            color: @base00;
          }
        }
        .warning, .critical, .urgent {
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
        #workspaces { padding-left: 0px; padding-right: 4px; }
        #workspaces button { padding: 5px 6px; }
        #workspaces button.active { background-color: @base0C; color: @base00; }
        #workspaces button.urgent { color: @base00; }
        #workspaces button:hover { background-color: @base09; color: @base00; }
        tooltip { background: @base01; }
        tooltip label { color: @base05; }
        #clock { color: @base05; padding: 0 10px; }
        #battery { min-width: 55px; color: @base0D; padding: 0 10px; }
        #battery.charging, #battery.full, #battery.plugged { color: @base0B; }
        #battery.critical:not(.charging) { color: @base08; }
        #network { color: @base0B; padding: 0 10px; }
        #network.disconnected { color: @base05; }
        #pulseaudio { color: @base06; padding: 0 10px; }
        #tray { padding: 0 8px 0 10px; }
      '';
    };
}

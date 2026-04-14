{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.wayland;
  colors = config.lib.stylix.colors.withHashtag;
in {
  config = lib.mkIf cfg.enable {
    xdg.configFile = {
      "wlogout/icons" = {
        source = ../hyprland/conf/wlogout/icons;
        recursive = true;
      };
      "wlogout/layout" = {
        source = ../hyprland/conf/wlogout/layout;
      };
      "wlogout/style.css".text = ''
        /** ********** Fonts ********** **/
        * {
            font-family: "JetBrainsMono Nerd Font", sans-serif;
            font-size: 14px;
            font-weight: bold;
        }

        /** ********** Main Window ********** **/
        window {
          background-color: ${colors.base00};
        }

        /** ********** Buttons ********** **/
        button {
          background-color: ${colors.base01};
            color: ${colors.base05};
          border: 2px solid ${colors.base02};
          border-radius: 20px;
          background-repeat: no-repeat;
          background-position: center;
          background-size: 35%;
        }

        button:focus, button:active, button:hover {
          background-color: ${colors.base0D};
          outline-style: none;
        }

        /** ********** Icons ********** **/
        #lock {
            background-image: image(url("icons/lock.png"), url("/usr/share/wlogout/icons/lock.png"));
        }

        #logout {
            background-image: image(url("icons/logout.png"), url("/usr/share/wlogout/icons/logout.png"));
        }

        #suspend {
            background-image: image(url("icons/suspend.png"), url("/usr/share/wlogout/icons/suspend.png"));
        }

        #hibernate {
            background-image: image(url("icons/hibernate.png"), url("/usr/share/wlogout/icons/hibernate.png"));
        }

        #shutdown {
            background-image: image(url("icons/shutdown.png"), url("/usr/share/wlogout/icons/shutdown.png"));
        }

        #reboot {
            background-image: image(url("icons/reboot.png"), url("/usr/share/wlogout/icons/reboot.png"));
        }
      '';
    };
  };
}

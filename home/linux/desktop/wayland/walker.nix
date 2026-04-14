{
  config,
  lib,
  ...
}: let
  cfg = config.modules.desktop.wayland;
  colors = config.lib.stylix.colors.withHashtag;
in {
  config = lib.mkIf cfg.enable {
    services.walker = {
      enable = true;
      systemd.enable = true;
      settings = {
        close_when_open = true;
        search.placeholder = "Search apps, files, commands...";
        list = {
          max_entries = 12;
          show_initial_entries = true;
        };
        builtins.switcher.prefix = "/";
      };

      theme = {
        name = "stylix";
        layout = {
          ui.anchors = {
            bottom = true;
            left = true;
            right = true;
            top = true;
          };
          ui.window = {
            h_align = "fill";
            v_align = "fill";
            box = {
              h_align = "center";
              width = 680;
              margins.top = 130;
              search.spacing = 10;
              scroll.list = {
                max_height = 520;
                min_width = 620;
                width = 620;
                margins.top = 10;
              };
            };
          };
        };

        style = ''
          #window,
          #box,
          #aiScroll,
          #aiList,
          #search,
          #password,
          #input,
          #prompt,
          #clear,
          #typeahead,
          #list,
          child,
          scrollbar,
          slider,
          #item,
          #text,
          #label,
          #bar,
          #sub,
          #activationlabel {
            all: unset;
          }

          * {
            font-family: "JetBrainsMono Nerd Font";
            font-size: 15px;
          }

          #window {
            color: ${colors.base05};
          }

          #box {
            background: alpha(${colors.base00}, 0.92);
            border: 1px solid ${colors.base02};
            border-radius: 14px;
            box-shadow:
              0 12px 28px alpha(#000000, 0.35),
              0 2px 8px alpha(#000000, 0.22);
            padding: 20px;
          }

          #search {
            background: ${colors.base01};
            border: 1px solid ${colors.base02};
            border-radius: 10px;
            padding: 10px 12px;
          }

          #prompt {
            color: ${colors.base0D};
            margin-right: 10px;
          }

          #clear {
            color: ${colors.base08};
          }

          #input,
          #typeahead {
            color: ${colors.base05};
          }

          #input placeholder {
            color: ${colors.base04};
          }

          child {
            border-radius: 10px;
            margin: 3px 0;
            padding: 10px 12px;
          }

          child:selected,
          child:hover {
            background: alpha(${colors.base0D}, 0.22);
          }

          #label {
            font-weight: 600;
          }

          #sub {
            color: ${colors.base04};
            font-size: 0.85em;
          }

          #activationlabel {
            color: ${colors.base0A};
          }
        '';
      };
    };
  };
}

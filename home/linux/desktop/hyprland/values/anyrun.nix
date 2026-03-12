{
  pkgs,
  config,
  anyrun,
  ...
}: let
  colors = config.lib.stylix.colors;
  # Convert base16 hex to rgba() with opacity for translucent UI elements
  hexToRgba = hex: alpha: let
    r = builtins.fromTOML "v = 0x${builtins.substring 0 2 hex}";
    g = builtins.fromTOML "v = 0x${builtins.substring 2 2 hex}";
    b = builtins.fromTOML "v = 0x${builtins.substring 4 2 hex}";
  in "rgba(${toString r.v}, ${toString g.v}, ${toString b.v}, ${alpha})";
in {
  programs.anyrun = {
    enable = true;
    config = {
      plugins = with anyrun.packages.${pkgs.system}; [
        applications
        randr
        rink
        shell
        symbols
        translate
      ];

      width.fraction = 0.3;
      y.absolute = 15;
      hidePluginInfo = true;
      closeOnClick = true;
    };

    # Custom CSS for anyrun, themed by Stylix
    extraCss = ''
      @define-color bg-col  ${hexToRgba colors.base00 "0.7"};
      @define-color bg-col-light ${hexToRgba colors.base0C "0.7"};
      @define-color border-col ${hexToRgba colors.base00 "0.7"};
      @define-color selected-col ${hexToRgba colors.base0D "0.7"};
      @define-color fg-col ${colors.withHashtag.base05};
      @define-color fg-col2 ${colors.withHashtag.base08};

      * {
        transition: 200ms ease;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 1.3rem;
      }

      #window {
        background: transparent;
      }

      #plugin,
      #main {
        border: 3px solid @border-col;
        color: @fg-col;
        background-color: @bg-col;
      }
      /* anyrun's input window - Text */
      #entry {
        color: @fg-col;
        background-color: @bg-col;
      }

      /* anyrun's output matches entries - Base */
      #match {
        color: @fg-col;
        background: @bg-col;
      }

      /* anyrun's selected entry */
      #match:selected {
        color: @fg-col2;
        background: @selected-col;
      }

      #match {
        padding: 3px;
        border-radius: 16px;
      }

      #entry, #plugin:hover {
        border-radius: 16px;
      }

      box#main {
        background: ${hexToRgba colors.base00 "0.7"};
        border: 1px solid @border-col;
        border-radius: 15px;
        padding: 5px;
      }
    '';
  };
}

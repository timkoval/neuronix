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
      "mako/icons" = {
        source = ../hyprland/conf/mako/icons;
        recursive = true;
      };
      "mako/config".text = ''
        ## Mako configuration file

        # GLOBAL CONFIGURATION OPTIONS
        max-history=100
        sort=-time

        # BINDING OPTIONS
        on-button-left=dismiss
        on-button-middle=none
        on-button-right=dismiss-all
        on-touch=dismiss
        on-notify=exec mpv /usr/share/sounds/freedesktop/stereo/message.oga

        # STYLE OPTIONS
        font=JetBrains Mono 10
        width=300
        height=100
        margin=10
        padding=15
        border-size=2
        border-radius=0
        icons=1
        max-icon-size=48
        icon-location=left
        markup=1
        actions=1
        history=1
        text-alignment=left
        default-timeout=5000
        ignore-timeout=0
        max-visible=5
        layer=overlay
        anchor=top-right

        background-color=${colors.base00}
        text-color=${colors.base05}
        border-color=${colors.base02}
        progress-color=over ${colors.base0D}

        [urgency=low]
        border-color=${colors.base02}
        default-timeout=2000

        [urgency=normal]
        border-color=${colors.base02}
        default-timeout=5000

        [urgency=high]
        border-color=${colors.base08}
        text-color=${colors.base08}
        default-timeout=0

        [category=mpd]
        border-color=${colors.base0A}
        default-timeout=2000
        group-by=category
      '';
    };
  };
}

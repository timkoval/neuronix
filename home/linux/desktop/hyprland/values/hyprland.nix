{
  pkgs,
  lib,
  config,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
in {
  # NOTE:
  # We have to enable hyprland/i3's systemd user service in home-manager,
  # so that gammastep/wallpaper-switcher's user service can be start correctly!
  # they are all depending on hyprland/i3's user graphical-session
  wayland.windowManager.hyprland = {
    enable = true;
    # Hyprland colors are managed by Stylix
    settings = {
      env = [
        "NIXOS_OZONE_WL,1" # for any ozone-based browser & electron apps to run on wayland
        "MOZ_ENABLE_WAYLAND,1" # for firefox to run on wayland
        "MOZ_WEBRENDER,1"
        # misc
        "_JAVA_AWT_WM_NONREPARENTING,1"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "QT_QPA_PLATFORM,wayland"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];
    };
    package = pkgs.hyprland;
    extraConfig = builtins.readFile ../conf/hyprland.conf;
    # gammastep/wallpaper-switcher need this to be enabled.
    systemd.enable = true;
  };

  # NOTE: this executable is used by greetd to start a wayland session when system boot up
  # with such a vendor-no-locking script, we can switch to another wayland compositor without modifying greetd's config in NixOS module
  home.file.".wayland-session" = {
    source = "${pkgs.hyprland}/bin/Hyprland";
    executable = true;
  };

  # hyprland configs, based on https://github.com/notwidow/hyprland
  xdg.configFile = {
    # ── Mako (notification daemon) ──
    # Icons stay as static files; config is generated with Stylix colors
    "hypr/mako/icons" = {
      source = ../conf/mako/icons;
      recursive = true;
    };
    "hypr/mako/config".text = ''
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

    # ── Scripts ──
    "hypr/scripts" = {
      source = ../conf/scripts;
      recursive = true;
    };

    # ── Waybar ──
    # Non-CSS files stay static; style.css is generated with Stylix colors
    "hypr/waybar/config.jsonc" = {
      source = ../conf/waybar/config.jsonc;
    };
    "hypr/waybar/style.css".text = let
      c = config.lib.stylix.colors;
    in ''
      /* Color palette managed by Stylix — Gruvbox Light Medium */
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

    # ── Wlogout ──
    # Icons and layout stay static; style.css is generated with Stylix colors
    "hypr/wlogout/icons" = {
      source = ../conf/wlogout/icons;
      recursive = true;
    };
    "hypr/wlogout/layout" = {
      source = ../conf/wlogout/layout;
    };
    "hypr/wlogout/style.css".text = ''
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

    # music player - mpd
    "mpd" = {
      source = ../conf/mpd;
      recursive = true;
    };
  };
}

{
  modules.desktop = {
    wayland = {
      shell.backend = "quickshell";
      idle.backend = "hypridle";
      screenshot.annotator = "satty";
      wallpaper.backend = "swww";
      wallpaper.video.enable = false;
    };
    # hyprland = {
    #   nvidia = true;
    #   screenshot.backend = "hyprshot";
    #   settings = {
    #     monitor = "DP-2,highres,auto,1.5,bitdepth,10";
    #   };
    # };
    # i3.nvidia = true;
  };
  modules.editors.emacs = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    # extraConfig = ''
    #   Host github.com
    #       IdentityFile ~/.ssh/idols-ai
    #       # Specifies that ssh should only use the identity file explicitly configured above
    #       # required to prevent sending default identity files first.
    #       IdentitiesOnly yes
    # '';
  };
}

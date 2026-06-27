{
  pkgs,
  pkgs-unstable,
  ...
}:
# media - control and enjoy audio/video
{
  home.packages = with pkgs; [
    # audio control
    pavucontrol
    playerctl
    pulsemixer
    imv # simple image viewer

    # nvtop

    # video/audio tools
    # cava # for visualizing audio
    libva-utils
    vdpauinfo
    vulkan-tools

    # notes
    oxipng
    git-crypt
    obsidian

    #    okular # pdf viewer
  ];

  programs = {
    mpv = {
      enable = true;
      defaultProfiles = ["gpu-hq"];
      scripts = [pkgs.mpvScripts.mpris];
    };
  };

  services = {
    playerctld.enable = true;
  };
}

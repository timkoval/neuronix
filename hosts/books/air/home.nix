{
  modules.desktop = {
    # hyprland = {
    #   nvidia = true;
    #   settings = {
    #     # Configure your Display resolution, offset, scale and Monitors here, use `hyprctl monitors` to get the info.
    #     #   highres:      get the best possible resolution
    #     #   auto:         postition automatically
    #     #   1.5:          scale to 1.5 times
    #     #   bitdepth,10:  enable 10 bit support
    #     monitor = "DP-2,highres,auto,1.5,bitdepth,10";
    #   };
    # };
    # i3.nvidia = true;
  };
  modules.editors.emacs = {
    enable = false;
  };

  programs.ssh = {
    enable = true;
  };
}

{
  lib,
  pkgs,
  ...
}:
###########################################################
#
# QuteBrowser Configuration
#
###########################################################
{
  programs.qutebrowser = {
    enable = false; # broken to install from nix registry:
  };
  xdg.configFile."qutebrowser/config.py".source = ./config.py;
}

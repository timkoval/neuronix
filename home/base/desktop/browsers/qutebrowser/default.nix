{
  lib,
  pkgs,
  ...
}:
###########################################################
#
# QuteBrowser Configuration
# Theme is managed by Stylix when programs.qutebrowser.enable = true
#
###########################################################
{
  programs.qutebrowser = {
    enable = false; # broken to install from nix registry:
  };
  xdg.configFile."qutebrowser/config.py".source = ./config.py;
  # gruvbox.py removed — Stylix handles theming
}

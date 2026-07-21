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
    enable = true;
  };
  xdg.configFile."qutebrowser/config.py".source = ./config.py;
  xdg.dataFile."qutebrowser/js/qb_translate.js".source = ./qb_translate.js;
  # gruvbox.py removed — Stylix handles theming
}

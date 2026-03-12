{
  lib,
  pkgs,
  ...
}:
###########################################################
#
# Kitty Configuration
#
# Useful Hot Keys for Linux(replace `ctrl + shift` with `cmd` on macOS)):
#   1. Increase Font Size: `ctrl + shift + =` | `ctrl + shift + +`
#   2. Decrease Font Size: `ctrl + shift + -` | `ctrl + shift + _`
#   3. And Other common shortcuts such as Copy, Paste, Cursor Move, etc.
#
###########################################################
{
  programs.kitty = {
    enable = true;
    # Font name and color scheme are managed by Stylix; override size per-platform
    font.size = lib.mkForce (
      if pkgs.stdenv.isDarwin
      then 14
      else 13
    );

    # consistent with wezterm
    keybindings = {
      "ctrl+shift+m" = "toggle_maximized";
      "ctrl+shift+f" = "show_scrollback"; # search in the current window
    };

    settings = {
      background_opacity = lib.mkForce "0.93";
      macos_option_as_alt = true; # Option key acts as Alt on macOS
      enable_audio_bell = false;
      tab_bar_edge = "top"; # tab bar on top
      #  Spawn fish in login mode
      shell = "${pkgs.fish}/bin/fish --login";
    };

    # macOS specific settings
    darwinLaunchOptions = ["--start-as=maximized"];
  };
}

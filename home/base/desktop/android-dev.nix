{
  pkgs,
  lib,
  pkgs-unstable,
  ...
}: {
  #############################################################
  #
  #  Android development environment
  #
  #############################################################

  # android-studio is x86_64-linux-only in nixpkgs, so only install it on
  # Linux — this module is shared with darwin via home/base/desktop.
  home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    pkgs-unstable.android-studio # Android IDE
    # pkgs.scrcpy # screen mirror & control Android devices via USB/TCP
    # pkgs.android-tools # adb, fastboot
  ];
}

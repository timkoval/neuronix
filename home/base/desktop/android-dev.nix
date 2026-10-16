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

  home.packages =
    [
      pkgs.android-tools # adb, fastboot
      # pkgs.scrcpy # screen mirror & control Android devices via USB/TCP
    ]
    # android-studio is x86_64-linux-only in nixpkgs, so only install it on
    # Linux — this module is shared with darwin via home/base/desktop.
    ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
      pkgs-unstable.android-studio # Android IDE
    ];
}

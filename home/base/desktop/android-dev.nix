{
  pkgs,
  pkgs-unstable,
  ...
}: {
  #############################################################
  #
  #  Android development environment
  #
  #############################################################

  home.packages = with pkgs; [
    pkgs-unstable.android-studio # Android IDE
    # scrcpy # screen mirror & control Android devices via USB/TCP
    # android-tools # adb, fastboot
  ];
}

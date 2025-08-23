{
  pkgs,
  pkgs-unstable,
  ...
}: {
  home.packages = with pkgs; [
    # GUI apps
    # e-book viewer(.epub/.mobi/...)
    # do not support .pdf
    # foliate

    # instant messaging
    # telegram-desktop
    # discord
 #    pkgs-unstable.qq # https://github.com/NixOS/nixpkgs/tree/master/pkgs/applications/networking/instant-messengers/qq
    # teams-for-linux

    # remote desktop(rdp connect)
    # remmina
    # freerdp # required by remmina
    
    # rpi-imager # iso flashing tool

    # misc
    # flameshot
    # ventoy # multi-boot usb creator
  ];

  # GitHub CLI tool
  programs.gh = {
    enable = false;
  };

  # allow fontconfig to discover fonts and configurations installed through home.packages
  # Install fonts at system-level, not user-level
  fonts.fontconfig.enable = false;
}

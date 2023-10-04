{pkgs, ...}: {
  imports = [
    ./creative.nix
    ./gtk.nix
    ./immutable-file.nix
    ./media.nix
    ./ssh.nix
    ./wallpaper.nix
    ./xdg.nix
  ];

  home.packages = with pkgs; [
    # GUI apps
    insomnia # REST client
    wireshark # network analyzer

    # e-book viewer(.epub/.mobi/...)
    # do not support .pdf
    foliate

    # instant messaging
    telegram-desktop
    discord

    # remote desktop(rdp connect)
    remmina
    freerdp # required by remmina

    # misc
    flameshot
  ];

  # GitHub CLI tool
  programs.gh = {
    enable = true;
  };
}

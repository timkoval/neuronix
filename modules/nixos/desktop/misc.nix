{
  config,
  lib,
  pkgs,
  ghostty,
  ...
}: {
  # add user's shell into /etc/shells
  environment.shells = with pkgs; [
    bashInteractive
    nushell
  ];
  # set user's default shell system-wide
  users.defaultUserShell = pkgs.bashInteractive;

  # fix for `sudo xxx` in kitty/wezterm and other modern terminal emulators
  security.sudo.keepTerminfo = true;

  environment.variables = {
    # fix https://github.com/NixOS/nixpkgs/issues/238025
    TZ = "${config.time.timeZone}";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    ventoy
    gnumake

    colmena # nixos's remote deployment tool
    ghostty.packages."${pkgs.system}".default
  ];

  services = {
    gvfs.enable = true; # Mount, trash, and other functionalities
    tumbler.enable = true; # Thumbnail support for images
    # https://flatpak.org/setup/NixOS
    flatpak.enable = true;
  };

  programs = {
    # The OpenSSH agent remembers private keys for you
    # so that you don’t have to type in passphrases every time you make an SSH connection.
    # Use `ssh-add` to add a key to the agent.
    ssh.startAgent = true;
    # dconf is a low-level configuration system.
    dconf.enable = true;

    # thunar file manager(part of xfce) related options
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
    };
  };
}

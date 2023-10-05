{config, ...} @ args:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).


{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../../modules/nixos/fhs-fonts.nix
    ../../../modules/nixos/libvirt.nix
    ../../../modules/nixos/core-desktop.nix
    ../../../modules/nixos/remote-building.nix
    ../../../modules/nixos/user-group.nix

    # ../../../secrets/nixos.nix
    ];
  
  nixpkgs.overlays = import ../../../overlays args;

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    systemd-boot.enable = true;
  };
  
  boot.initrd.enable = true;
  boot.initrd.luks.devices = {
  luksroot = {
      device = "/dev/disk/by-uuid/bd1433a9-428c-4b61-ad3d-e5bcdd610a52";
      preLVM = true;

    };
  };

  networking = {
    hostName = "BOOK09F7NP";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}


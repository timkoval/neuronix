{config, lib, pkgs, ...} @ args:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).


{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./apple-silicon-support

    ../../modules/nixos/fhs-fonts.nix
    ../../modules/nixos/libvirt.nix
    ../../modules/nixos/core-desktop.nix
    ../../modules/nixos/remote-building.nix
    ../../modules/nixos/user-group.nix

    # ../../secrets/nixos.nix
  ];
  
  nixpkgs.overlays = import ../../overlays args;

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
    };
    systemd-boot.enable = true;
  };
  
  # Remove if you get an error that an x86_64-linux builder is required
  hardware.asahi.pkgsSystem = "x86_64-linux";

  # Specifying path to peripheral firmware files
  hardware.asahi.peripheralFirmwareDirectory = ./firmware;
  
  # boot.kernelModules = [ ];

  networking = {
    hostName = "air";
    # wireless.enable = false; # Enables wireless support via wpa_supplicant.
    wireless.iwd = {
      enable = true;
      settings.General.EnableNetworkConfiguration = true;
    };

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    # networkmanager.enable = true;
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


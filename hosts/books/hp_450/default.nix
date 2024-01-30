{config, lib, pkgs, ...} @ args:
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

    # ../../secrets/nixos.nix
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
        device = "/dev/disk/by-uuid/1b1860f5-4a6c-4362-8b50-de6d985fdcc9";
        preLVM = true;
    };
  };

  boot.kernelModules = [ ];

  # power management stuff
  boot.kernelParams = ["intel_pstate=disable"];
  services.power-profiles-daemon = {
      enable = lib.mkForce false;
  };
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0=75;
      STOP_CHARGE_THRESH_BAT0=80;

      CPU_SCALING_GOVERNOR_ON_AC="schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT="schedutil";

      CPU_SCALING_MIN_FREQ_ON_AC=800000;
      CPU_SCALING_MAX_FREQ_ON_AC=3500000;
      CPU_SCALING_MIN_FREQ_ON_BAT=800000;
      CPU_SCALING_MAX_FREQ_ON_BAT=2300000;

      # Enable audio power saving for Intel HDA, AC97 devices (timeout in secs).
      # A value of 0 disables, >=1 enables power saving (recommended: 1).
      # Default: 0 (AC), 1 (BAT)
      SOUND_POWER_SAVE_ON_AC=0;
      SOUND_POWER_SAVE_ON_BAT=1;

      # Runtime Power Management for PCI(e) bus devices: on=disable, auto=enable.
      # Default: on (AC), auto (BAT)
      RUNTIME_PM_ON_AC="on";
      RUNTIME_PM_ON_BAT="auto";

      # Battery feature drivers: 0=disable, 1=enable
      # Default: 1 (all)
      NATACPI_ENABLE=1;
      TPACPI_ENABLE=1;
      TPSMAPI_ENABLE=1;
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


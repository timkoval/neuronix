{config, lib, pkgs, ...} @ args:
# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).


{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./apple-silicon-support

    # ../../../secrets/nixos.nix
  ];
  
  nixpkgs.overlays = import ../../../overlays args;
  # nixpkgs.config.allowUnsupportedSystem = true;

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = false;
    };
    systemd-boot.enable = true;
  };
  boot.kernelPatches = [{
  name = "waydroid";
  patch = null;
  extraConfig = ''
    ANDROID_BINDER_IPC y
    ANDROID_BINDERFS y
    ANDROID_BINDER_DEVICES binder,hwbinder,vndbinder
    CONFIG_ASHMEM y
    CONFIG_ANDROID_BINDERFS y
    CONFIG_ANDROID_BINDER_IPC y
  '';
}];
  
  hardware = {
    asahi = {
      # Remove if you get an error that an x86_64-linux builder is required
      # pkgsSystem = "x86_64-linux";
      # Specifying path to peripheral firmware files
      peripheralFirmwareDirectory = ./firmware;
      addEdgeKernelConfig = true;
      useExperimentalGPUDriver = true;
      experimentalGPUInstallMode = "replace";
      withRust = true;
    };
    opengl.enable = true;
  };


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


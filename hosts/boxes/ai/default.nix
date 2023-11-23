{config, ...} @ args:
#############################################################
#
#  Ai - my main computer, with NixOS + I5-13600KF + RTX 4090 GPU, for gaming & daily use.
#
#############################################################
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../../modules/nixos/fhs-fonts.nix
    ../../../modules/nixos/libvirt.nix
    ../../../modules/nixos/core-desktop.nix
    ../../../modules/nixos/remote-building.nix
    ../../../modules/nixos/user-group.nix

  #  ../../../secrets/nixos.nix
  ];

  nixpkgs.overlays = import ../../../overlays args;

  # Enable binfmt emulation of aarch64-linux, this is required for cross compilation.
  boot.binfmt.emulatedSystems = ["aarch64-linux" "riscv64-linux"];
  # supported fil systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    #"zfs"
    "ntfs"
    "fat"
    "vfat"
    "exfat"
  ];

  # Bootloader.
  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi"; # ← use the same mount point here.
    };
    systemd-boot.enable = true;
  };

  networking = {
    hostName = "ai";
    wireless.enable = false; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;
  };

  virtualisation.docker.storageDriver = "btrfs";

  # for Nvidia GPU
  services.xserver.videoDrivers = ["nvidia"]; # will install nvidia-vaapi-driver by default
  hardware.nvidia = {
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Modesetting is needed for most Wayland compositors
    modesetting.enable = true;
    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    open = false;

    powerManagement.enable = true;
  };
  virtualisation.docker.enableNvidia = true; # for nvidia-docker

  hardware.opengl = {
    enable = true;
    # if hardware.opengl.driSupport is enabled, mesa is installed and provides Vulkan for supported hardware.
    driSupport = true;
    # needed by nvidia-docker
    driSupport32Bit = true;
  };
  
    boot.kernelModules = [ "88x2bu" ];
  boot.extraModulePackages = [    
    (config.boot.kernelPackages.rtl88x2bu.overrideAttrs (old: {
      prePatch = old.prePatch + ''
        substituteInPlace Makefile --replace "CONFIG_CONCURRENT_MODE = n" "CONFIG_CONCURRENT_MODE = y"
      '';
    }))
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}

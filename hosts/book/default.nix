{config, system, pkgs, ... } @ args: 
{
  imports = [
    # Include the results of the hardware scan.
    # ./hardware-configuration.nix

    ../../../modules/nixos/fhs-fonts.nix
    ../../../modules/nixos/libvirt.nix
    ../../../modules/nixos/core-desktop.nix
    ../../../modules/nixos/remote-building.nix
    ../../../modules/nixos/user-group.nix

    ../../../secrets/nixos.nix
  ];

  inherit pkgs system;
  zfs-root = {
    boot = {
      devNodes = "/dev/disk/by-id/";
      bootDevices = [  "nvme-SAMSUNG_MZVLQ512HBLU-00BH1_S671NX6TC63700" ];
      immutable = false;
      availableKernelModules = [  "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      removableEfi = true;
      kernelParams = [ ];
      sshUnlock = {
        # read sshUnlock.txt file.
        enable = false;
        authorizedKeys = [ ];
      };
    };
    networking = {
      # read changeHostName.txt file.
      hostName = "exampleHost";
      timeZone = "Europe/Berlin";
      hostId = "bd8ad562";
    };
  };
  
  nixpkgs.overlays = import ../../../overlays args;

  ## enable ZFS auto snapshot on datasets
  ## You need to set the auto snapshot property to "true"
  ## on datasets for this to work, such as
  # zfs set com.sun:auto-snapshot=true rpool/nixos/home
  services.zfs = {
    autoSnapshot = {
      enable = false;
      flags = "-k -p --utc";
      monthly = 48;
    };
  };

  boot.zfs.forceImportRoot = false;

  networking = {
    hostName = "BOOK09F7NP";
    wireless.enable = true; # Enables wireless support via wpa_supplicant.

    # Configure network proxy if necessary
    # proxy.default = "http://user:password@proxy:port/";
    # proxy.noProxy = "127.0.0.1,localhost,internal.domain";

    networkmanager.enable = true;

    enableIPv6 = false; # disable ipv6
    # interfaces.enp5s0 = {
    #   useDHCP = false;
    #   ipv4.addresses = [
    #     {
    #       address = "192.168.5.100";
    #       prefixLength = 24;
    #     }
    #   ];
    # };
    # defaultGateway = "192.168.5.201";
    # nameservers = [
    #   "119.29.29.29" # DNSPod
    #   "223.5.5.5" # AliDNS
    # ];
  };

  virtualisation.docker.storageDriver = "btrfs";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}

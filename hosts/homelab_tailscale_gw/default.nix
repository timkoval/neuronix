{vars_networking, ...}:
#############################################################
#
#  Tailscale Gateway(homelab subnet router) - a NixOS VM running on Proxmox
#
#############################################################
let
  hostName = "tailscale_gw"; # Define your hostname.
  hostAddress = vars_networking.hostAddress.${hostName};
in {
  imports = [
    ./tailscale.nix
  ];

  # supported file systems, so we can mount any removable disks with these filesystems
  boot.supportedFilesystems = [
    "ext4"
    "btrfs"
    "xfs"
    "fat"
    "vfat"
    "exfat"
  ];

  networking = {
    inherit hostName;
    inherit (vars_networking) defaultGateway nameservers;

    networkmanager.enable = false;
    interfaces.ens18 = {
      useDHCP = false;
      ipv4.addresses = [hostAddress];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?
}

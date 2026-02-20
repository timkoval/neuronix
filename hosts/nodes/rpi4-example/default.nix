{
  hostVars,
  lib,
  ...
}: {
  networking.hostName = hostVars.hostname;
  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  boot.loader.grub.devices = ["nodev"];
  users.allowNoPasswordLogin = true;
  system.stateVersion = "24.11";
}

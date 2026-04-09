{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
#    (modulesPath + "/hardware/cpu/intel-npu.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/05ca02df-a850-4ee9-89ae-6922aa99bd2a";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd:3" ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/05ca02df-a850-4ee9-89ae-6922aa99bd2a";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd:3" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D3CB-2D45";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

#  hardware.cpu.intel.npu.enable = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}

{lib, ...}: {
  imports = [
    ../base/btrbk.nix
    ../base/core.nix
    ../base/earlyoom.nix
    ../base/i18n.nix
    ../base/nix.nix
    ../base/networking.nix
    ../base/packages.nix
    ../base/power.nix
    ../base/remote-building.nix
    ../base/user-group.nix
    ../base/virtualisation.nix
    ../base/zram.nix
    ../../base.nix
  ];

  neuronix = {
    docker.enable = lib.mkDefault false;
    earlyoom.enable = lib.mkDefault true;
    networking.avahi.enable = lib.mkDefault false;
    packages.extended.enable = lib.mkDefault false;
    power.enable = lib.mkDefault false;
    zram.enable = lib.mkDefault true;
    btrbk.enable = lib.mkDefault false;
  };
}

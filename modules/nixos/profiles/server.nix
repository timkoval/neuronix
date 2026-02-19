{lib, ...}: {
  imports = [
    ./minimal.nix
    ../base/packages.nix
    ../base/power.nix
    ../base/virtualisation.nix
    ../base/zram.nix
    ../base/btrbk.nix
  ];

  neuronix = {
    docker.enable = lib.mkOverride 900 true;
    networking.avahi.enable = lib.mkOverride 900 true;
    packages.extended.enable = lib.mkOverride 900 true;
    power.enable = lib.mkOverride 900 true;
    zram.enable = lib.mkOverride 900 true;
    btrbk.enable = lib.mkOverride 900 true;
  };
}

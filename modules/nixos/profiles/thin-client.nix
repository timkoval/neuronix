{lib, ...}: {
  imports = [
    ./minimal.nix
    ../base/power.nix
  ];

  neuronix = {
    power.enable = lib.mkOverride 900 true;
    zram.enable = lib.mkOverride 900 true;
    networking.avahi.enable = lib.mkOverride 900 true;
  };
}

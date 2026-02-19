{lib, ...}: {
  imports = [
    ./server.nix
    ../desktop
  ];

  neuronix = {
    power.enable = lib.mkOverride 800 true;
    networking.avahi.enable = lib.mkOverride 800 true;
  };
}
